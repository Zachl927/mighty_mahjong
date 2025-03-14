extends Node
class_name GameRules

# Enums for clarity
enum TileType {TIAO, TONG, WAN}
enum ActionType {DRAW, DISCARD, PENG, GANG, WIN}
enum TurnState {WAITING, DRAW_PHASE, DISCARD_PHASE, CLAIM_PHASE, GAME_OVER}

# Constants
const MAX_PLAYERS = 4
const INITIAL_HAND_SIZE = 13
const MAX_TILES_IN_HAND = 14 # After drawing and before discarding
const WINNING_SETS_REQUIRED = 4
const WINNING_PAIRS_REQUIRED = 1

# Game configuration (Sichuan rules specific)
const MAX_SUITS_PER_HAND = 2 # Sichuan rule: only 2 suits allowed
const SEVEN_PAIRS_VALID = true # Allow 7 pairs as a winning condition

# Properties for turn management
var _current_player_index: int = 0
var _current_turn_state: int = TurnState.WAITING
var _player_ids: Array = []
var _last_discarded_tile = null
var _last_action_player_id = -1

# Signals for game events
signal action_validated(player_id, action_type, is_valid, message)
signal turn_changed(player_id, turn_state)
signal game_over(winner_id, score)

# Initialize the game with player IDs
func initialize_game(player_ids: Array) -> void:
	_player_ids = player_ids.duplicate()
	_current_player_index = 0
	_current_turn_state = TurnState.WAITING
	_last_discarded_tile = null
	_last_action_player_id = -1

# Start the game
func start_game() -> void:
	if _player_ids.size() < 2:
		push_error("Cannot start game with fewer than 2 players")
		return
	
	_current_player_index = 0
	_current_turn_state = TurnState.DRAW_PHASE
	emit_signal("turn_changed", get_current_player_id(), _current_turn_state)

# Get the current player's ID
func get_current_player_id() -> int:
	if _player_ids.size() == 0:
		return -1
	return _player_ids[_current_player_index]

# Get the current turn state
func get_current_turn_state() -> int:
	return _current_turn_state

# Advance to the next player
func next_player() -> void:
	_current_player_index = (_current_player_index + 1) % _player_ids.size()
	_current_turn_state = TurnState.DRAW_PHASE
	emit_signal("turn_changed", get_current_player_id(), _current_turn_state)

# Handle a player's action
func handle_action(player_id: int, action_type: int, tile_data = null, player_hand = null) -> bool:
	# Validate if the action is legal
	var is_valid = validate_action(player_id, action_type, tile_data, player_hand)
	
	if is_valid:
		# Update game state based on the action
		match action_type:
			ActionType.DRAW:
				_current_turn_state = TurnState.DISCARD_PHASE
			
			ActionType.DISCARD:
				_last_discarded_tile = tile_data
				_last_action_player_id = player_id
				_current_turn_state = TurnState.CLAIM_PHASE
				
				# Check if anyone can claim this tile (simplified for now)
				# In a real implementation, we'd wait for player responses
				call_deferred("_check_claims_and_advance")
			
			ActionType.PENG:
				_current_turn_state = TurnState.DISCARD_PHASE
				# Player who claimed gets next turn
				_set_current_player(player_id)
			
			ActionType.GANG:
				_current_turn_state = TurnState.DRAW_PHASE  # Player draws again after Gang
				# Player who claimed gets next turn
				_set_current_player(player_id)
			
			ActionType.WIN:
				_current_turn_state = TurnState.GAME_OVER
				var score = calculate_score(player_hand, tile_data, player_id == _last_action_player_id)
				emit_signal("game_over", player_id, score)
		
		emit_signal("turn_changed", get_current_player_id(), _current_turn_state)
		return true
	
	return false

# Set the current player to a specific player ID
func _set_current_player(player_id: int) -> void:
	var index = _player_ids.find(player_id)
	if index >= 0:
		_current_player_index = index

# Check for claims after a discard and advance if no claims
func _check_claims_and_advance() -> void:
	# In a real implementation, we'd wait for player responses
	# For now, we'll just advance to the next player
	next_player()

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
	
	# Check if it's the player's turn and the correct phase
	if not _is_valid_turn(_player_id, action_type):
		message = "Not your turn or invalid action for current phase"
		emit_signal("action_validated", _player_id, action_type, false, message)
		return false
	
	match action_type:
		ActionType.DRAW:
			is_valid = validate_draw(_player_id, player_hand)
			message = "Cannot draw: hand is full" if not is_valid else "Draw valid"
		ActionType.DISCARD:
			is_valid = validate_discard(_player_id, _tile_data, player_hand)
			message = "Cannot discard: invalid tile" if not is_valid else "Discard valid"
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

# Check if it's valid for the player to take this action in the current turn state
func _is_valid_turn(player_id, action_type) -> bool:
	# If game is over, no actions are valid
	if _current_turn_state == TurnState.GAME_OVER:
		return false
	
	# If waiting, no actions are valid
	if _current_turn_state == TurnState.WAITING:
		return false
	
	# For draw phase
	if _current_turn_state == TurnState.DRAW_PHASE:
		# Only current player can draw
		if action_type == ActionType.DRAW and player_id == get_current_player_id():
			return true
		return false
	
	# For discard phase
	if _current_turn_state == TurnState.DISCARD_PHASE:
		# Only current player can discard
		if action_type == ActionType.DISCARD and player_id == get_current_player_id():
			return true
		# Win is also possible if player just drew the winning tile
		if action_type == ActionType.WIN and player_id == get_current_player_id():
			return true
		return false
	
	# For claim phase
	if _current_turn_state == TurnState.CLAIM_PHASE:
		# Anyone except the discarder can claim
		if player_id != _last_action_player_id:
			if action_type == ActionType.PENG or action_type == ActionType.GANG or action_type == ActionType.WIN:
				return true
		return false
	
	return false

# Validate if player can draw a tile
func validate_draw(_player_id, player_hand):
	# Check if player's hand is at maximum capacity
	if player_hand and player_hand.get_tile_count() >= MAX_TILES_IN_HAND:
		return false
	
	return true

# Validate if player can discard a tile
func validate_discard(_player_id, _tile_data, player_hand):
	# Check if player has the tile in hand
	if player_hand and not player_hand.has_tile(_tile_data):
		return false
	
	return true

# Validate if player can peng (claim a discarded tile to form a set of 3)
func validate_peng(_player_id, _tile_data, player_hand):
	# Can only claim the last discarded tile
	if not _tile_data or not _last_discarded_tile or not _tile_data.equals(_last_discarded_tile):
		return false
	
	# Check if player already has 2 matching tiles in hand
	if player_hand:
		var matching_count = player_hand.count_matching_tiles(_tile_data)
		return matching_count >= 2
	
	return false

# Validate if player can gang (claim a discarded tile to form a set of 4 or add to existing set of 3)
func validate_gang(_player_id, _tile_data, player_hand):
	# For claiming a discarded tile
	if _last_discarded_tile and _tile_data and _tile_data.equals(_last_discarded_tile):
		# Check if player has 3 matching tiles in hand
		if player_hand:
			var matching_count = player_hand.count_matching_tiles(_tile_data)
			if matching_count >= 3:
				return true
	# For self-gang (concealed or adding to exposed pung)
	elif player_hand:
		# For concealed gang (all 4 in hand)
		var matching_count = player_hand.count_matching_tiles(_tile_data)
		if matching_count >= 4:
			return true
			
		# For exposed gang (adding to existing exposed set)
		var exposed_sets = player_hand.get_exposed_sets()
		for set_data in exposed_sets:
			if set_data["type"] == player_hand.SetType.PONG and set_data["tiles"][0].equals(_tile_data):
				return true
		
	return false

# Validate if a player's hand is a winning hand
func validate_win(_player_id, _tile_data, player_hand):
	if not player_hand:
		return false
	
	var tiles_to_check = player_hand.get_all_tiles().duplicate()
	
	# If claiming a discard, add it to the tiles to check
	if _current_turn_state == TurnState.CLAIM_PHASE and _last_discarded_tile:
		tiles_to_check.append(_last_discarded_tile)
	
	# First check: we need the right number of tiles (usually 14 for a complete hand)
	var total_tiles = tiles_to_check.size()
	if total_tiles != MAX_TILES_IN_HAND:
		return false
		
	# Second check: enforce suit restriction (max 2 suits in Sichuan rules)
	if not is_valid_suit_restriction(tiles_to_check):
		return false
		
	# Check winning conditions:
	
	# 1. Standard winning pattern: 4 sets (pong/chow) and 1 pair
	if has_standard_winning_pattern(player_hand, _last_discarded_tile if _current_turn_state == TurnState.CLAIM_PHASE else null):
		return true
		
	# 2. Seven pairs (if allowed by rules)
	if SEVEN_PAIRS_VALID and has_seven_pairs(player_hand, _last_discarded_tile if _current_turn_state == TurnState.CLAIM_PHASE else null):
		return true
		
	return false

# Check if hand has the standard winning pattern of 4 sets and 1 pair
func has_standard_winning_pattern(player_hand, claimed_tile = null):
	# Get all tiles including the claimed tile if any
	var all_tiles = player_hand.get_all_tiles().duplicate()
	if claimed_tile:
		all_tiles.append(claimed_tile)
	
	# Get exposed sets
	var exposed_sets = player_hand.get_exposed_sets()
	var exposed_set_count = exposed_sets.size()
	
	# If we already have more than 4 exposed sets, it can't form a valid pattern
	if exposed_set_count > WINNING_SETS_REQUIRED:
		return false
	
	# Remove tiles in exposed sets from consideration
	var concealed_tiles = all_tiles.duplicate()
	for set_data in exposed_sets:
		for tile in set_data["tiles"]:
			var idx = concealed_tiles.find(tile)
			if idx >= 0:
				concealed_tiles.remove_at(idx)
	
	# Use recursive pattern checking for concealed tiles
	return _check_standard_pattern(concealed_tiles, WINNING_SETS_REQUIRED - exposed_set_count, WINNING_PAIRS_REQUIRED)

# Recursive function to check if tiles can form standard pattern
func _check_standard_pattern(tiles, sets_needed, pairs_needed):
	# Base case: If we need 0 sets and 0 pairs, we've found a valid pattern
	if sets_needed == 0 and pairs_needed == 0 and tiles.size() == 0:
		return true
		
	# If no more tiles but we still need sets or pairs, it's invalid
	if tiles.size() == 0:
		return false
		
	# Try forming a pair if needed
	if pairs_needed > 0 and tiles.size() >= 2:
		var first_tile = tiles[0]
		# Find a matching tile for the pair
		for i in range(1, tiles.size()):
			if tiles[i].equals(first_tile):
				# Found a pair, remove these tiles and recurse
				var remaining_tiles = tiles.duplicate()
				remaining_tiles.remove_at(i)  # Remove second tile first to maintain indices
				remaining_tiles.remove_at(0)  # Remove first tile
				if _check_standard_pattern(remaining_tiles, sets_needed, pairs_needed - 1):
					return true
	
	# Try forming a pong if we need sets
	if sets_needed > 0 and tiles.size() >= 3:
		var first_tile = tiles[0]
		var matching_indices = []
		
		# Find matching tiles for a pong
		for i in range(1, tiles.size()):
			if tiles[i].equals(first_tile):
				matching_indices.append(i)
				if matching_indices.size() == 2:  # We found 3 identical tiles
					var remaining_tiles = tiles.duplicate()
					# Remove from highest index to lowest to maintain indices
					remaining_tiles.remove_at(matching_indices[1])
					remaining_tiles.remove_at(matching_indices[0])
					remaining_tiles.remove_at(0)
					if _check_standard_pattern(remaining_tiles, sets_needed - 1, pairs_needed):
						return true
					break
	
	# Try forming a chow if we need sets
	if sets_needed > 0 and tiles.size() >= 3:
		var first_tile = tiles[0]
		
		# Only attempt chow with suit tiles
		if first_tile.type == Tile.TileType.SUIT and first_tile.value < 8:  # Value must be < 8 to form a sequence
			var plus_one_idx = -1
			var plus_two_idx = -1
			
			# Find the +1 and +2 tiles for a chow
			for i in range(1, tiles.size()):
				if tiles[i].type == Tile.TileType.SUIT and tiles[i].suit_type == first_tile.suit_type:
					if tiles[i].value == first_tile.value + 1 and plus_one_idx == -1:
						plus_one_idx = i
					elif tiles[i].value == first_tile.value + 2 and plus_two_idx == -1:
						plus_two_idx = i
			
			# If we found a complete sequence
			if plus_one_idx != -1 and plus_two_idx != -1:
				var remaining_tiles = tiles.duplicate()
				# Remove from highest index to lowest to maintain indices
				remaining_tiles.remove_at(max(plus_one_idx, plus_two_idx))
				remaining_tiles.remove_at(min(plus_one_idx, plus_two_idx))
				remaining_tiles.remove_at(0)
				if _check_standard_pattern(remaining_tiles, sets_needed - 1, pairs_needed):
					return true
	
	# If we can't form any valid pattern with the first tile, try with it removed
	var new_tiles = tiles.duplicate()
	new_tiles.remove_at(0)
	return _check_standard_pattern(new_tiles, sets_needed, pairs_needed)

# Check if hand has seven pairs (a special winning condition)
func has_seven_pairs(player_hand, claimed_tile = null):
	# Seven pairs only works with concealed tiles
	if player_hand.get_exposed_sets().size() > 0:
		return false
		
	# Get all tiles including the claimed tile if any
	var all_tiles = player_hand.get_all_tiles().duplicate()
	if claimed_tile:
		all_tiles.append(claimed_tile)
		
	# We need exactly 14 tiles for seven pairs
	if all_tiles.size() != MAX_TILES_IN_HAND:
		return false
		
	# Group tiles by their unique identifiers
	var tile_groups = {}
	for tile in all_tiles:
		var key = str(tile.type) + "_" + str(tile.suit_type) + "_" + str(tile.value)
		
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
func calculate_score(player_hand, winning_tile = null, is_self_drawn = false):
	var score = 0
	
	# Base score
	if is_self_drawn:
		score += 2  # Self-drawn win
	else:
		score += 1  # Win from discard
	
	# Get all tiles including the winning tile
	var all_tiles = player_hand.get_all_tiles().duplicate()
	if winning_tile:
		all_tiles.append(winning_tile)
	
	# Get exposed sets
	var exposed_sets = player_hand.get_exposed_sets()
	
	# Check for bonus points
	
	# All Pongs bonus (no chows)
	var has_chow = false
	for set_data in exposed_sets:
		if set_data["type"] == player_hand.SetType.CHOW:
			has_chow = true
			break
	
	# If we didn't find any chows in exposed sets, check concealed tiles
	if not has_chow and not has_seven_pairs(player_hand, winning_tile):
		# If it's a standard pattern win, all sets must be pongs
		score += 1  # All pongs bonus
	
	# Clean hand (one suit only)
	var suits_used = {}
	for tile in all_tiles:
		suits_used[tile.suit_type] = true
	
	if suits_used.size() == 1:
		score += 1  # Clean hand bonus
	
	# All concealed bonus
	if exposed_sets.size() == 0:
		score += 1  # All concealed bonus
	
	# Seven pairs bonus
	if has_seven_pairs(player_hand, winning_tile):
		score += 2  # Seven pairs bonus
	
	# Return the total score
	return score
