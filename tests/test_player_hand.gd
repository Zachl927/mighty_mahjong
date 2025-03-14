extends Control

# References
var player_hand: PlayerHand
var player_hand_display: PlayerHandDisplay
var tile_manager: TileManager

# Currently selected tile index (for backward compatibility)
var selected_tile_index: int = -1
# Track all selected indices
var selected_indices: Array = []

func _ready():
	# Initialize components
	tile_manager = TileManager.new(128)  # Use 128px size tiles
	player_hand = PlayerHand.new()
	
	# Create and position the player hand display
	var hand_display_scene = load("res://scenes/player_hand.tscn")
	player_hand_display = hand_display_scene.instantiate()
	$MainContainer/PlayerHandContainer.add_child(player_hand_display)
	player_hand_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Set the player hand reference in the display
	player_hand_display.set_player_hand(player_hand)
	
	# Connect to tile selection signals
	player_hand_display.tile_selected.connect(_on_tile_selected)
	player_hand_display.tiles_selection_changed.connect(_on_tiles_selection_changed)
	
	# Create the complete set of tiles
	tile_manager.create_complete_set()
	
	# Display initial information
	update_info_text("Test initialized. Use the buttons below to test player hand functionality.")

# Add a random tile to the player's hand
func _on_add_random_tile_button_pressed():
	# Make sure we have a wall to draw from
	if tile_manager.get_wall_size() == 0:
		tile_manager.create_wall()
	
	# Draw a random tile
	var tile = tile_manager.draw_tile()
	if tile:
		player_hand.add_tile(tile)
		update_info_text("Added random tile: " + tile.get_tile_name())
	else:
		update_info_text("Failed to add tile: Wall is empty!")

# Remove the selected tiles from the player's hand
func _on_remove_selected_tile_button_pressed():
	if selected_indices.is_empty():
		update_info_text("No tiles selected! Select one or more tiles first.")
		return
	
	# Use the new multi-selection removal function
	var removed_tiles = player_hand_display.remove_selected_tiles()
	
	if removed_tiles.size() > 0:
		var message = "Removed " + str(removed_tiles.size()) + " tile(s): "
		for i in range(removed_tiles.size()):
			if i > 0:
				message += ", "
			message += removed_tiles[i].get_tile_name()
		update_info_text(message)
		
		# Reset selection tracking
		selected_tile_index = -1
		selected_indices.clear()
	else:
		update_info_text("Failed to remove tiles!")

# Sort the tiles in the player's hand
func _on_sort_tiles_button_pressed():
	player_hand.sort_tiles()
	update_info_text("Tiles sorted!")

# Display information about the player's hand
func _on_show_info_button_pressed():
	var info = "Hand information:\n"
	info += "- Total tiles: " + str(player_hand.get_tile_count()) + "\n\n"
	
	# List all tiles
	info += "Tiles in hand:\n"
	for i in range(player_hand.get_tile_count()):
		var tile = player_hand.get_tile_at(i)
		var prefix = "  " + str(i+1) + ". "
		if selected_indices.has(i):
			prefix += "[SELECTED] "
		info += prefix + tile.get_tile_name() + "\n"
	
	# Find potential sets
	var potential_sets = player_hand.find_potential_sets()
	info += "\nPotential sets: " + str(potential_sets.size()) + "\n"
	
	for i in range(potential_sets.size()):
		var set_data = potential_sets[i]
		var set_type_name = ""
		match set_data.type:
			PlayerHand.SetType.PONG: set_type_name = "Pong"
			PlayerHand.SetType.KONG: set_type_name = "Kong"
			PlayerHand.SetType.CHOW: set_type_name = "Chow"
		
		info += "  " + str(i+1) + ". " + set_type_name + ": "
		for tile in set_data.tiles:
			info += tile.get_tile_name() + ", "
		info = info.substr(0, info.length() - 2)  # Remove last comma
		info += "\n"
	
	# Get exposed sets
	var exposed_sets = player_hand.get_exposed_sets()
	info += "\nExposed sets: " + str(exposed_sets.size()) + "\n"
	
	for i in range(exposed_sets.size()):
		var set_data = exposed_sets[i]
		var set_type_name = ""
		match set_data.type:
			PlayerHand.SetType.PONG: set_type_name = "Pong"
			PlayerHand.SetType.KONG: set_type_name = "Kong"
			PlayerHand.SetType.CHOW: set_type_name = "Chow"
		
		info += "  " + str(i+1) + ". " + set_type_name + ": "
		for tile in set_data.tiles:
			info += tile.get_tile_name() + ", "
		info = info.substr(0, info.length() - 2)  # Remove last comma
		info += "\n"
	
	# Check if winning hand
	info += "\nIs winning hand: " + str(player_hand.is_winning_hand())
	
	update_info_text(info)

# Add specific sets of tiles for testing
func _on_add_specific_sets_button_pressed():
	# Clear the current hand
	while player_hand.get_tile_count() > 0:
		player_hand.remove_tile_at(0)
	
	# Add a potential Pong (3 identical tiles)
	var pong_tiles = []
	for _i in range(3):
		var tile = Tile.new(Tile.TileType.SUIT, 5, Tile.SuitType.BAMBOO)
		tile_manager.get_asset_manager().set_tile_texture(tile)
		pong_tiles.append(tile)
	
	# Add a potential Chow (3 consecutive tiles)
	var chow_tiles = []
	for i in range(3):
		var tile = Tile.new(Tile.TileType.SUIT, 2 + i, Tile.SuitType.CIRCLE)
		tile_manager.get_asset_manager().set_tile_texture(tile)
		chow_tiles.append(tile)
	
	# Add a pair (for potential winning hand) - using PINYIN suit instead of honor tiles
	var pair_tiles = []
	for _i in range(2):
		var tile = Tile.new(Tile.TileType.SUIT, 7, Tile.SuitType.PINYIN)
		tile_manager.get_asset_manager().set_tile_texture(tile)
		pair_tiles.append(tile)
	
	# Add all tiles to the hand
	for tile in pong_tiles:
		player_hand.add_tile(tile)
	
	for tile in chow_tiles:
		player_hand.add_tile(tile)
	
	for tile in pair_tiles:
		player_hand.add_tile(tile)
	
	update_info_text("Added test sets to hand: 1 Pong (Bamboo 5), 1 Chow (Circle 2-4), and 1 Pair (Pinyin 7)")

# Try to form a set with the selected tile
func _on_form_set_button_pressed():
	if selected_tile_index < 0:
		update_info_text("No tile selected! Select a tile first.")
		return
	
	var tile = player_hand.get_tile_at(selected_tile_index)
	var potential_sets = player_hand.find_potential_sets()
	
	# Find a potential set containing this tile
	var set_to_form = null
	for set_data in potential_sets:
		for set_tile in set_data.tiles:
			if set_tile.tile_id == tile.tile_id:
				set_to_form = set_data
				break
		if set_to_form:
			break
	
	if set_to_form:
		# Create a simulated "discard" tile for the form_set function
		# In a real game, this would be a tile discarded by another player
		var discard_tile = null
		
		# For testing, we'll use the first tile of the set as the "discarded" tile
		var set_tiles = set_to_form.tiles.duplicate()
		discard_tile = set_tiles[0]
		
		# Remove that tile from hand first (simulating it was discarded by another player)
		player_hand.remove_tile_by_id(discard_tile.tile_id)
		
		# Now try to form the set
		var success = player_hand.form_set(set_to_form.type, discard_tile)
		if success:
			update_info_text("Successfully formed " + set_type_to_string(set_to_form.type) + " set with " + discard_tile.get_tile_name())
		else:
			# If failed, add the tile back
			player_hand.add_tile(discard_tile)
			update_info_text("Failed to form set with " + discard_tile.get_tile_name())
	else:
		update_info_text("Selected tile is not part of any potential set.")

# Handle tile selection
func _on_tile_selected(index):
	selected_tile_index = index
	update_info_text("Selected tile at index " + str(index) + ": " + player_hand.get_tile_at(index).get_tile_name())

# Handle multiple tile selection
func _on_tiles_selection_changed(indices):
	selected_indices = indices
	
	var message = "Selected " + str(indices.size()) + " tile(s): "
	for i in range(indices.size()):
		if i > 0:
			message += ", "
		message += player_hand.get_tile_at(indices[i]).get_tile_name()
	
	if indices.size() > 0:
		selected_tile_index = indices[0]  # For backward compatibility
	else:
		selected_tile_index = -1
	
	update_info_text(message)

# Update the info text label
func update_info_text(text):
	$MainContainer/InfoPanel/VBoxContainer/InfoTextEdit.text = text

# Convert set type to string
func set_type_to_string(set_type):
	match set_type:
		PlayerHand.SetType.PONG: return "Pong"
		PlayerHand.SetType.KONG: return "Kong"
		PlayerHand.SetType.CHOW: return "Chow"
		_: return "Unknown"
