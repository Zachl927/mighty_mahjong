extends Node
class_name PlayerHand

# Player ID
var player_id: int = -1

# Player's hand tiles
var tiles: Array[Tile] = []

# Exposed/melded sets of tiles (e.g., claimed Pongs, Kongs)
var exposed_sets: Array = []

# Signals
signal tile_added(tile: Tile)
signal tile_removed(tile: Tile)
signal hand_sorted()
signal potential_sets_changed(potential_sets: Array)

# Constants for set types
enum SetType {PONG, KONG, CHOW}

func _init():
	pass
	
# Add a tile to the hand
func add_tile(tile: Tile) -> void:
	if tile:
		tiles.append(tile)
		sort_tiles()
		tile_added.emit(tile)
		_update_potential_sets()

# Add multiple tiles to the hand
func add_tiles(new_tiles: Array[Tile]) -> void:
	for tile in new_tiles:
		tiles.append(tile)
	
	sort_tiles()
	_update_potential_sets()

# Remove a tile from the hand
func remove_tile(tile: Tile) -> bool:
	for i in range(tiles.size()):
		if tiles[i].tile_id == tile.tile_id:
			var removed_tile = tiles[i]
			tiles.remove_at(i)
			tile_removed.emit(removed_tile)
			_update_potential_sets()
			return true
	
	return false

# Remove a tile by index
func remove_tile_at(index: int) -> Tile:
	if index >= 0 and index < tiles.size():
		var removed_tile = tiles[index]
		tiles.remove_at(index)
		tile_removed.emit(removed_tile)
		_update_potential_sets()
		return removed_tile
	return null

# Clear all tiles from the hand
func clear_hand() -> void:
	tiles.clear()
	exposed_sets.clear()
	_update_potential_sets()

# Get the total number of tiles in hand
func get_tile_count() -> int:
	return tiles.size()

# Get a tile at a specific index
func get_tile_at(index: int) -> Tile:
	if index < 0 or index >= tiles.size():
		return null
	
	return tiles[index]

# Get all tiles
func get_all_tiles() -> Array[Tile]:
	return tiles

# Sort tiles by their sort value
func sort_tiles() -> void:
	tiles.sort_custom(func(a, b): return a.get_sort_value() < b.get_sort_value())
	hand_sorted.emit()

# Check if the hand can form the specified set with a discarded tile
func can_form_set(tile: Tile, set_type: int) -> bool:
	match set_type:
		SetType.PONG:
			return can_form_pong(tile)
		SetType.KONG:
			return can_form_kong(tile)
		SetType.CHOW:
			return can_form_chow(tile)
	
	return false

# Check if player can form a Pong (3 identical tiles)
func can_form_pong(tile: Tile) -> bool:
	if not tile or not (tile.is_suit() or tile.is_honor()):
		return false
	
	var matching_count = 0
	for hand_tile in tiles:
		if hand_tile.matches(tile):
			matching_count += 1
	
	# Need at least 2 matching tiles in hand to form a Pong with 1 discarded tile
	return matching_count >= 2

# Check if player can form a Kong (4 identical tiles)
func can_form_kong(tile: Tile) -> bool:
	if not tile or not (tile.is_suit() or tile.is_honor()):
		return false
	
	var matching_count = 0
	for hand_tile in tiles:
		if hand_tile.matches(tile):
			matching_count += 1
	
	# Need 3 matching tiles in hand to form a Kong with 1 discarded tile
	return matching_count >= 3

# Check if player can form a Chow (3 consecutive tiles of the same suit)
func can_form_chow(tile: Tile) -> bool:
	if not tile or not tile.is_suit():
		return false
	
	# For a Chow, we need to check if we have the adjacent tiles of the same suit
	var value = tile.value
	var suit = tile.suit_type
	
	var has_value_minus_1 = false
	var has_value_minus_2 = false
	var has_value_plus_1 = false
	var has_value_plus_2 = false
	
	for hand_tile in tiles:
		if hand_tile.is_suit() and hand_tile.suit_type == suit:
			if hand_tile.value == value - 1:
				has_value_minus_1 = true
			elif hand_tile.value == value - 2:
				has_value_minus_2 = true
			elif hand_tile.value == value + 1:
				has_value_plus_1 = true
			elif hand_tile.value == value + 2:
				has_value_plus_2 = true
	
	# Possible Chow combinations: (value-2, value-1, value), (value-1, value, value+1), (value, value+1, value+2)
	return (has_value_minus_2 and has_value_minus_1) or (has_value_minus_1 and has_value_plus_1) or (has_value_plus_1 and has_value_plus_2)

# Find all potential sets in the hand (without a discarded tile)
func find_potential_sets() -> Array:
	var potential_sets = []
	
	# Find potential Pongs (3 identical tiles)
	var matching_tiles = {}
	for tile in tiles:
		if not tile.is_bonus():  # Bonus tiles cannot form sets
			if not matching_tiles.has(tile.tile_id):
				matching_tiles[tile.tile_id] = []
			matching_tiles[tile.tile_id].append(tile)
	
	# Check for Pongs and Kongs
	for tile_id in matching_tiles:
		var same_tiles = matching_tiles[tile_id]
		if same_tiles.size() >= 3:
			# We have a potential Pong
			potential_sets.append({
				"type": SetType.PONG,
				"tiles": same_tiles.slice(0, 3)
			})
		
		if same_tiles.size() >= 4:
			# We have a potential Kong
			potential_sets.append({
				"type": SetType.KONG,
				"tiles": same_tiles.slice(0, 4)
			})
	
	# Find potential Chows (3 consecutive tiles of the same suit)
	# Group tiles by suit
	var suit_groups = {}
	for tile in tiles:
		if tile.is_suit():
			var suit = tile.suit_type
			if not suit_groups.has(suit):
				suit_groups[suit] = {}
			
			if not suit_groups[suit].has(tile.value):
				suit_groups[suit][tile.value] = []
			
			suit_groups[suit][tile.value].append(tile)
	
	# Check each suit for consecutive values
	for suit in suit_groups:
		var values = suit_groups[suit].keys()
		values.sort()
		
		for i in range(len(values) - 2):
			if values[i + 1] == values[i] + 1 and values[i + 2] == values[i] + 2:
				# Found three consecutive values
				var chow_tiles = [
					suit_groups[suit][values[i]][0],
					suit_groups[suit][values[i + 1]][0],
					suit_groups[suit][values[i + 2]][0]
				]
				
				potential_sets.append({
					"type": SetType.CHOW,
					"tiles": chow_tiles
				})
	
	return potential_sets

# Form a set from tiles in hand and a discarded tile
func form_set(discard_tile: Tile, set_type: int) -> Array:
	var set_tiles = []
	
	match set_type:
		SetType.PONG:
			# Add the discarded tile to the set
			set_tiles.append(discard_tile)
			
			# Find 2 matching tiles in hand
			var matches_found = 0
			var indices_to_remove = []
			
			for i in range(tiles.size()):
				if tiles[i].matches(discard_tile) and matches_found < 2:
					set_tiles.append(tiles[i])
					indices_to_remove.append(i)
					matches_found += 1
			
			# Remove tiles from hand (in reverse order to maintain correct indices)
			indices_to_remove.sort()
			indices_to_remove.reverse()
			
			for index in indices_to_remove:
				tiles.remove_at(index)
		
		SetType.KONG:
			# Add the discarded tile to the set
			set_tiles.append(discard_tile)
			
			# Find 3 matching tiles in hand
			var matches_found = 0
			var indices_to_remove = []
			
			for i in range(tiles.size()):
				if tiles[i].matches(discard_tile) and matches_found < 3:
					set_tiles.append(tiles[i])
					indices_to_remove.append(i)
					matches_found += 1
			
			# Remove tiles from hand (in reverse order to maintain correct indices)
			indices_to_remove.sort()
			indices_to_remove.reverse()
			
			for index in indices_to_remove:
				tiles.remove_at(index)
		
		SetType.CHOW:
			# For Chow, we need specific consecutive values
			var value = discard_tile.value
			var suit = discard_tile.suit_type
			
			# Determine which Chow pattern we can form
			var needed_values = []
			
			# Possible Chow combinations: (value-2, value-1, value), (value-1, value, value+1), (value, value+1, value+2)
			if can_form_chow(discard_tile):
				# Check which pattern we can form
				var has_minus_1 = false
				var has_minus_2 = false
				var has_plus_1 = false
				var has_plus_2 = false
				
				for hand_tile in tiles:
					if hand_tile.is_suit() and hand_tile.suit_type == suit:
						if hand_tile.value == value - 1:
							has_minus_1 = true
						elif hand_tile.value == value - 2:
							has_minus_2 = true
						elif hand_tile.value == value + 1:
							has_plus_1 = true
						elif hand_tile.value == value + 2:
							has_plus_2 = true
				
				if has_minus_2 and has_minus_1:
					needed_values = [value - 2, value - 1, value]
				elif has_minus_1 and has_plus_1:
					needed_values = [value - 1, value, value + 1]
				elif has_plus_1 and has_plus_2:
					needed_values = [value, value + 1, value + 2]
				
				# Add tiles to set and track which to remove
				var indices_to_remove = []
				
				for val in needed_values:
					if val == value:
						set_tiles.append(discard_tile)
					else:
						# Find this value in hand
						for i in range(tiles.size()):
							if tiles[i].is_suit() and tiles[i].suit_type == suit and tiles[i].value == val:
								set_tiles.append(tiles[i])
								indices_to_remove.append(i)
								break
				
				# Remove tiles from hand (in reverse order)
				indices_to_remove.sort()
				indices_to_remove.reverse()
				
				for index in indices_to_remove:
					tiles.remove_at(index)
	
	# Add to exposed sets if we formed a valid set
	if set_tiles.size() > 0:
		exposed_sets.append({
			"type": set_type,
			"tiles": set_tiles
		})
		
		_update_potential_sets()
	
	return set_tiles

# Get all exposed sets
func get_exposed_sets() -> Array:
	return exposed_sets

# Check if hand has a specific tile
func has_tile(target_tile: Tile) -> bool:
	for tile in tiles:
		if tile.matches(target_tile):
			return true
	return false

# Count how many of a specific tile type are in the hand
func count_matching_tiles(target_tile: Tile) -> int:
	var count = 0
	for tile in tiles:
		if tile.matches(target_tile):
			count += 1
	return count

# Internal method to update potential sets and emit signal
func _update_potential_sets() -> void:
	var potential_sets = find_potential_sets()
	potential_sets_changed.emit(potential_sets)

# Returns true if the hand is a valid winning hand
func is_winning_hand() -> bool:
	# This is a simplified win check - real implementation would need to check 
	# specific rules for Sichuan Mahjong winning patterns
	
	# Clone the hand for analysis
	var analysis_tiles = tiles.duplicate()
	
	# Check for any tiles not in sets
	var sets = []
	var has_pair = false
	
	# Keep looking for sets until we can't find any more
	var found_set = true
	while found_set and analysis_tiles.size() >= 3:
		found_set = false
		
		# Check for pongs
		var matching_tiles = {}
		for tile in analysis_tiles:
			if not matching_tiles.has(tile.tile_id):
				matching_tiles[tile.tile_id] = []
			matching_tiles[tile.tile_id].append(tile)
		
		for tile_id in matching_tiles:
			if matching_tiles[tile_id].size() >= 3:
				# Found a pong
				found_set = true
				sets.append({
					"type": SetType.PONG,
					"tiles": matching_tiles[tile_id].slice(0, 3)
				})
				
				# Remove these tiles from analysis
				for i in range(3):
					analysis_tiles.erase(matching_tiles[tile_id][i])
				break
		
		if found_set:
			continue
		
		# Check for chows
		var suit_groups = {}
		for tile in analysis_tiles:
			if tile.is_suit():
				var suit = tile.suit_type
				if not suit_groups.has(suit):
					suit_groups[suit] = {}
				
				if not suit_groups[suit].has(tile.value):
					suit_groups[suit][tile.value] = []
				
				suit_groups[suit][tile.value].append(tile)
		
		for suit in suit_groups:
			var values = suit_groups[suit].keys()
			values.sort()
			
			for i in range(len(values) - 2):
				if values[i] + 1 == values[i + 1] and values[i] + 2 == values[i + 2]:
					# Found a chow
					found_set = true
					var chow_tiles = [
						suit_groups[suit][values[i]][0],
						suit_groups[suit][values[i + 1]][0],
						suit_groups[suit][values[i + 2]][0]
					]
					
					sets.append({
						"type": SetType.CHOW,
						"tiles": chow_tiles
					})
					
					# Remove these tiles from analysis
					for chow_tile in chow_tiles:
						analysis_tiles.erase(chow_tile)
					break
			
			if found_set:
				break
	
	# After removing all sets, we should have exactly 2 tiles left for a pair
	if analysis_tiles.size() == 2 and analysis_tiles[0].matches(analysis_tiles[1]):
		has_pair = true
	
	# A winning hand has 4 sets (either pongs or chows) and 1 pair
	return sets.size() == 4 and has_pair
