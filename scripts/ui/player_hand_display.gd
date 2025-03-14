extends Control
class_name PlayerHandDisplay

# Reference to the player's hand data
var player_hand: PlayerHand

# Tile display scale
var tile_scale: float = 1.0

# Signals
signal tile_selected(tile: Tile, index: int)
signal tiles_selection_changed(selected_indices: Array)

# Constants
const TILE_HOVER_RAISE: float = 15.0
const EXPOSED_SET_SPACING: float = 20.0

# Preload the tile scene
var tile_scene = preload("res://scenes/tile.tscn")

# Track selected tiles
var selected_indices: Array = []

func _ready():
	# Create a new PlayerHand if one isn't already assigned
	if player_hand == null:
		player_hand = PlayerHand.new()
		
	# Connect signals from the player hand
	player_hand.tile_added.connect(_on_tile_added)
	player_hand.tile_removed.connect(_on_tile_removed)
	player_hand.hand_sorted.connect(_on_hand_sorted)
	player_hand.potential_sets_changed.connect(_on_potential_sets_changed)

# Set the player hand reference
func set_player_hand(hand: PlayerHand) -> void:
	# Disconnect signals from old hand if exists
	if player_hand:
		player_hand.tile_added.disconnect(_on_tile_added)
		player_hand.tile_removed.disconnect(_on_tile_removed)
		player_hand.hand_sorted.disconnect(_on_hand_sorted)
		player_hand.potential_sets_changed.disconnect(_on_potential_sets_changed)
	
	player_hand = hand
	
	# Connect signals from new hand
	player_hand.tile_added.connect(_on_tile_added)
	player_hand.tile_removed.connect(_on_tile_removed)
	player_hand.hand_sorted.connect(_on_hand_sorted)
	player_hand.potential_sets_changed.connect(_on_potential_sets_changed)
	
	# Update display
	refresh_display()

# Set the scale of displayed tiles
func set_tile_scale(scale: float) -> void:
	tile_scale = scale
	refresh_display()

# Add a tile to the hand and update the display
func add_tile(tile: Tile) -> void:
	player_hand.add_tile(tile)
	# Display update handled by signal

# Remove a tile from the hand and update the display
func remove_tile(tile: Tile) -> bool:
	return player_hand.remove_tile(tile)
	# Display update handled by signal

# Get the PlayerHand reference
func get_player_hand() -> PlayerHand:
	return player_hand

# Get the currently selected tile indices
func get_selected_indices() -> Array:
	return selected_indices

# Clear all tile selections
func clear_selections() -> void:
	selected_indices.clear()
	refresh_hand_display()
	tiles_selection_changed.emit(selected_indices)

# Remove all selected tiles
func remove_selected_tiles() -> Array:
	var removed_tiles = []
	
	# Sort indices in descending order to remove from highest to lowest
	# This prevents index shifting issues during removal
	var sorted_indices = selected_indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	
	for index in sorted_indices:
		if index >= 0 and index < player_hand.get_tile_count():
			var tile = player_hand.get_tile_at(index)
			var removed_tile = player_hand.remove_tile_at(index)
			if removed_tile:
				removed_tiles.append(removed_tile)
	
	# Clear selections after removal
	selected_indices.clear()
	tiles_selection_changed.emit(selected_indices)
	
	return removed_tiles

# Refresh the entire display (both hand and exposed sets)
func refresh_display() -> void:
	refresh_hand_display()
	refresh_exposed_sets_display()

# Refresh just the main hand display
func refresh_hand_display() -> void:
	# Clear existing tiles
	for child in $MainHandContainer.get_children():
		child.queue_free()
	
	# Add all tiles from the player hand
	for i in range(player_hand.get_tile_count()):
		var tile = player_hand.get_tile_at(i)
		add_tile_to_display(tile, i)

# Add a single tile to the display
func add_tile_to_display(tile: Tile, index: int) -> void:
	var tile_display = tile_scene.instantiate()
	tile_display.set_tile(tile)
	tile_display.scale = Vector2(tile_scale, tile_scale)
	
	# Set custom data for identifying this tile later
	tile_display.set_meta("hand_index", index)
	
	# Set selection state
	if selected_indices.has(index):
		tile_display.set_selected(true)
	
	# Connect signals
	tile_display.connect("tile_selected", _on_tile_display_selected)
	
	$MainHandContainer.add_child(tile_display)

# Refresh the exposed sets display
func refresh_exposed_sets_display() -> void:
	# Clear existing sets
	for child in $ExposedSetsContainer/SetsGrid.get_children():
		child.queue_free()
	
	# Show or hide exposed sets section based on whether we have any
	var exposed_sets = player_hand.get_exposed_sets()
	$ExposedSetsContainer.visible = not exposed_sets.is_empty()
	
	# Add all exposed sets
	for set_data in exposed_sets:
		add_exposed_set_to_display(set_data)

# Add a single exposed set to the display
func add_exposed_set_to_display(set_data: Dictionary) -> void:
	var set_container = HBoxContainer.new()
	set_container.set_name("SetContainer")
	set_container.add_theme_constant_override("separation", -20)
	
	# Add each tile in the set
	for tile in set_data.tiles:
		var tile_display = tile_scene.instantiate()
		tile_display.set_tile(tile)
		tile_display.scale = Vector2(tile_scale * 0.8, tile_scale * 0.8)  # Slightly smaller
		tile_display.set_disabled(true)  # Make exposed sets non-interactive
		set_container.add_child(tile_display)
	
	# Add a separator after each set
	var separator = VSeparator.new()
	separator.custom_minimum_size.x = EXPOSED_SET_SPACING
	
	# Add both to the sets grid
	$ExposedSetsContainer/SetsGrid.add_child(set_container)
	$ExposedSetsContainer/SetsGrid.add_child(separator)

# Signal handlers
func _on_tile_added(tile: Tile) -> void:
	# Add the new tile to the display
	add_tile_to_display(tile, player_hand.get_tile_count() - 1)

func _on_tile_removed(tile: Tile) -> void:
	# Refresh the entire hand display since indices changed
	refresh_hand_display()

func _on_hand_sorted() -> void:
	# Refresh the hand display after sorting
	refresh_hand_display()

func _on_potential_sets_changed(potential_sets: Array) -> void:
	# This could be used to highlight potential sets in the UI
	# For now, just refreshing the display
	refresh_display()

# Handle tile selection from the display
func _on_tile_display_selected(tile_display) -> void:
	# Get the hand index from the metadata we stored
	var index = tile_display.get_meta("hand_index")
	var tile = player_hand.get_tile_at(index)
	
	# Toggle selection for this tile
	if selected_indices.has(index):
		selected_indices.erase(index)
		tile_display.set_selected(false)
	else:
		selected_indices.append(index)
		tile_display.set_selected(true)
	
	# Emit signals
	tile_selected.emit(tile, index)
	tiles_selection_changed.emit(selected_indices)

# Create a visual claim prompt for when another player discards a tile
func show_claim_prompt(discarded_tile: Tile) -> void:
	# Check what claims are possible
	var can_pong = player_hand.can_form_pong(discarded_tile)
	var can_kong = player_hand.can_form_kong(discarded_tile)
	var can_chow = player_hand.can_form_chow(discarded_tile)
	
	if not (can_pong or can_kong or can_chow):
		# No valid claims possible
		return
	
	# TODO: Implement claim popup UI
	# This would create a popup with buttons for Pong, Kong, Chow based on what's possible
	# When button is pressed, it would call player_hand.form_set with the appropriate type
	# For now we'll just print to the console
	print("Claim possible for tile: ", discarded_tile.get_tile_name())
	if can_pong:
		print("Can form Pong")
	if can_kong:
		print("Can form Kong")
	if can_chow:
		print("Can form Chow")
	
# Handle forming a set after claiming
func form_set_from_claim(discarded_tile: Tile, set_type: int) -> void:
	var set_tiles = player_hand.form_set(discarded_tile, set_type)
	if not set_tiles.is_empty():
		refresh_display()
