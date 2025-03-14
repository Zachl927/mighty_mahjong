extends Node

# References to UI elements
@onready var all_tiles_grid = $TabContainer/AllTiles/ScrollContainer/TilesGrid
@onready var distribution_test_container = $TabContainer/DistributionTest/VBoxContainer
@onready var status_label = $TabContainer/AllTiles/StatusLabel
@onready var size_option = $Controls/SizeOption
@onready var player_count_spinner = $Controls/PlayerCountSpinner

# Reference to managers
var tile_manager: TileManager
var asset_manager: TileAssetManager

var test_hand_containers = []
var selected_size = 128

func _ready():
    # Setup size dropdown
    size_option.clear()
    for size in TileAssetManager.TILE_SIZES:
        size_option.add_item(str(size), size)
    size_option.select(2)  # Default to 128px
    
    # Initialize the tile system
    initialize_tile_system()
    
    # Connect signals
    $Controls/ShuffleButton.pressed.connect(_on_shuffle_button_pressed)
    $Controls/DistributeButton.pressed.connect(_on_distribute_button_pressed)
    size_option.item_selected.connect(_on_size_option_selected)

func initialize_tile_system():
    # Create the tile manager with the selected size
    tile_manager = TileManager.new(selected_size)
    asset_manager = tile_manager.get_asset_manager()
    
    # Create the complete tile set
    var all_tiles = tile_manager.create_complete_set()
    status_label.text = "Loaded %d tiles" % all_tiles.size()
    
    # Display all the tiles in the grid
    display_all_tiles(all_tiles)

func display_all_tiles(tiles: Array[Tile]):
    # Clear existing tiles
    for child in all_tiles_grid.get_children():
        child.queue_free()
    
    # Create a new tile display for each tile
    for tile in tiles:
        var tile_display = preload("res://scenes/tile.tscn").instantiate()
        all_tiles_grid.add_child(tile_display)
        tile_display.set_tile(tile)
        
        # Connect signals
        tile_display.tile_selected.connect(_on_tile_selected)

func _on_tile_selected(tile_display: TileDisplay):
    var tile = tile_display.get_tile()
    if tile:
        status_label.text = "Selected: " + tile.get_display_name()

func _on_shuffle_button_pressed():
    # Clear distribution test
    clear_distribution_test()
    
    # Create a new wall (shuffled tiles)
    var wall = tile_manager.create_wall()
    status_label.text = "Shuffled %d tiles" % wall.size()
    
    # If we're in the distribution test tab, switch back to the all tiles tab
    # and make sure the tiles are displayed
    if $TabContainer.current_tab == 1:  # DistributionTest tab
        $TabContainer.current_tab = 0   # Switch to AllTiles tab
        # Re-display all tiles to make them visible
        display_all_tiles(tile_manager.all_tiles)

func _on_distribute_button_pressed():
    # Get player count
    var player_count = player_count_spinner.value
    
    # Create wall if not already created
    if tile_manager.get_wall_size() == 0:
        tile_manager.create_wall()
    
    # Clear previous distribution
    clear_distribution_test()
    
    # Distribute tiles to players
    var player_hands = tile_manager.distribute_initial_tiles(player_count)
    
    # Display the distributed hands
    for i in range(player_count):
        var container = create_player_hand_container(i)
        test_hand_containers.append(container)
        distribution_test_container.add_child(container)
        
        # Add a label for the player
        var label = Label.new()
        label.text = "Player %d:" % (i + 1)
        container.add_child(label)
        
        # Create a HBoxContainer for the tiles
        var hand_container = HBoxContainer.new()
        hand_container.name = "HandContainer"
        container.add_child(hand_container)
        
        # Add the tiles to the hand
        for tile in player_hands[i]:
            var tile_display = preload("res://scenes/tile.tscn").instantiate()
            hand_container.add_child(tile_display)
            tile_display.set_tile(tile)
            
            # Connect signals
            tile_display.tile_selected.connect(_on_tile_selected)
    
    # Update status
    status_label.text = "Distributed tiles to %d players. Each player has %d tiles." % [
        player_count, 
        13 # Sichuan Mahjong starts with 13 tiles per player
    ]
    
    # Switch to the distribution test tab
    $TabContainer.current_tab = 1

func create_player_hand_container(player_index: int) -> VBoxContainer:
    var container = VBoxContainer.new()
    container.name = "Player%d" % (player_index + 1)
    
    # Add some margin
    container.add_theme_constant_override("separation", 10)
    
    return container

func clear_distribution_test():
    for container in test_hand_containers:
        if is_instance_valid(container):
            container.queue_free()
    
    test_hand_containers.clear()

func _on_size_option_selected(index: int):
    selected_size = size_option.get_item_id(index)
    
    # Reinitialize the tile system with the new size
    initialize_tile_system()
    
    # Clear distribution test
    clear_distribution_test()
