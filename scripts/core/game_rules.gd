extends Node
class_name GameRules

# Enums for clarity
enum TileType {TIAO, TONG, WAN}
enum ActionType {DRAW, DISCARD, PENG, GANG, WIN}

# Constants
const MAX_PLAYERS = 4
const INITIAL_HAND_SIZE = 13
const MAX_TILES_IN_HAND = 14 # After drawing and before discarding
const WINNING_SETS_REQUIRED = 4
const WINNING_PAIRS_REQUIRED = 1

# Game configuration (Sichuan rules specific)
const MAX_SUITS_PER_HAND = 2 # Sichuan rule: only 2 suits allowed
const SEVEN_PAIRS_VALID = true # Allow 7 pairs as a winning condition

signal action_validated(player_id, action_type, is_valid, message)

# Returns true if a player's tiles contain only 2 or fewer suits
func is_valid_suit_restriction(tiles):
	var suits = {}
	for tile in tiles:
		suits[tile.suit_type] = true
	return suits.size() <= MAX_SUITS_PER_HAND

# Validate if a player can perform a specific action
func validate_action(_player_id, action_type, _tile_data = null, player_hand = null):
	var is_valid = false
	var message = ""
	
	match action_type:
		ActionType.DRAW:
			is_valid = validate_draw(_player_id, player_hand)
			message = "Cannot draw: not your turn or hand is full" if not is_valid else "Draw valid"
		ActionType.DISCARD:
			is_valid = validate_discard(_player_id, _tile_data, player_hand)
			message = "Cannot discard: not your turn or invalid tile" if not is_valid else "Discard valid"
		ActionType.PENG:
			is_valid = validate_peng(_player_id, _tile_data, player_hand)
			message = "Cannot peng: insufficient matching tiles" if not is_valid else "Peng valid"
		ActionType.GANG:
			is_valid = validate_gang(_player_id, _tile_data, player_hand)
			message = "Cannot gang: insufficient matching tiles" if not is_valid else "Gang valid"
		ActionType.WIN:
			is_valid = validate_win(_player_id, _tile_data, player_hand)
			message = "Not a winning hand" if not is_valid else "Win valid"
	
	# Emit signal with validation result
	emit_signal("action_validated", _player_id, action_type, is_valid, message)
	return is_valid

# Validate if player can draw a tile
func validate_draw(_player_id, player_hand):
	# Check if it's the player's turn (would be implemented with turn manager)
	# For now, assume turn validation is done elsewhere
	
	# Check if player's hand is at maximum capacity
	if player_hand and player_hand.get_tile_count() >= MAX_TILES_IN_HAND:
		return false
	
	return true

# Validate if player can discard a tile
func validate_discard(_player_id, _tile_data, player_hand):
	# Check if it's the player's turn (would be implemented with turn manager)
	# Check if player has the tile in hand
	if player_hand and not player_hand.has_tile(_tile_data):
		return false
	
	return true

# Validate if player can peng (claim a discarded tile to form a set of 3)
func validate_peng(_player_id, _tile_data, player_hand):
	# Check if player already has 2 matching tiles in hand
	if player_hand:
		var matching_count = player_hand.count_matching_tiles(_tile_data)
		return matching_count >= 2
	
	return false

# Validate if player can gang (claim a discarded tile to form a set of 4 or add to existing set of 3)
func validate_gang(_player_id, _tile_data, player_hand):
	# Check if player has 3 matching tiles in hand or an exposed set of 3
	if player_hand:
		# For concealed gang (all 4 in hand)
		var matching_count = player_hand.count_matching_tiles(_tile_data)
		if matching_count >= 3:
			return true
			
		# For exposed gang (adding to existing exposed set)
		# This would check exposed sets in player_hand
		
	return false

# Validate if a player's hand is a winning hand
func validate_win(_player_id, _tile_data, player_hand):
	if not player_hand:
		return false
		
	# First check: we need the right number of tiles (usually 14 for a complete hand)
	var total_tiles = player_hand.get_tile_count() + player_hand.get_total_exposed_tiles()
	if total_tiles != MAX_TILES_IN_HAND:
		return false
		
	# Second check: enforce suit restriction (max 2 suits in Sichuan rules)
	if not is_valid_suit_restriction(player_hand.get_all_tiles()):
		return false
		
	# Check winning conditions:
	
	# 1. Standard winning pattern: 4 sets (pong/chow) and 1 pair
	if has_standard_winning_pattern(player_hand):
		return true
		
	# 2. Seven pairs (if allowed by rules)
	if SEVEN_PAIRS_VALID and has_seven_pairs(player_hand):
		return true
		
	return false

# Check if hand has the standard winning pattern of 4 sets and 1 pair
func has_standard_winning_pattern(player_hand):
	# This is a simplified placeholder - actual implementation would be more complex
	# It would need to check all possible combinations of sets (pong/chow) and pairs
	
	# Get all possible sets in hand
	var potential_sets = player_hand.find_potential_sets()
	var exposed_sets = player_hand.get_exposed_sets()
	
	# Simple check: Do we have at least 4 sets and 1 pair?
	# This is simplified and not accurate for all hand patterns
	if potential_sets.size() + exposed_sets.size() >= WINNING_SETS_REQUIRED:
		# Check for at least one pair
		var pairs = []
		for i in range(player_hand.get_tile_count()):
			var tile = player_hand.get_tile_at(i)
			var count = player_hand.count_matching_tiles(tile)
			if count >= 2 and not pairs.has(tile.get_id()):
				pairs.append(tile.get_id())
				
		if pairs.size() >= WINNING_PAIRS_REQUIRED:
			return true
	
	return false

# Check if hand has seven pairs (a special winning condition)
func has_seven_pairs(player_hand):
	# Only concealed tiles matter for seven pairs
	if player_hand.get_exposed_sets().size() > 0:
		return false
		
	# We need exactly 14 tiles in hand
	if player_hand.get_tile_count() != MAX_TILES_IN_HAND:
		return false
		
	# Group tiles by their values
	var tile_groups = {}
	for i in range(player_hand.get_tile_count()):
		var tile = player_hand.get_tile_at(i)
		var key = str(tile.type) + "_" + str(tile.value)
		
		if not tile_groups.has(key):
			tile_groups[key] = 0
		tile_groups[key] += 1
	
	# Check if we have exactly 7 pairs
	var pair_count = 0
	for key in tile_groups:
		if tile_groups[key] == 2:
			pair_count += 1
		else:
			return false  # If any group is not a pair, it's not seven pairs
	
	return pair_count == 7

# Calculate the score for a winning hand
func calculate_score(_player_hand):
	# Placeholder for scoring logic
	var score = 0
	
	# Basic score
	score += 1
	
	# Add score for specific patterns (to be implemented)
	
	return score
