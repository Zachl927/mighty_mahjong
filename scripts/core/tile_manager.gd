extends Node
class_name TileManager

# The complete set of mahjong tiles
var all_tiles: Array[Tile] = []

# The wall (draw pile)
var wall: Array[Tile] = []

# Reference to the asset manager
var asset_manager: TileAssetManager

# Signals
signal wall_created(tile_count: int)
signal tiles_distributed(player_index: int, tiles: Array[Tile])
signal wall_empty

func _init(size: int = 128):
    # Create an asset manager with the specified tile size
    asset_manager = TileAssetManager.new(size)

# Create a complete set of mahjong tiles according to Sichuan rules
func create_complete_set() -> Array[Tile]:
    all_tiles.clear()
    
    # Create 4 copies of each suit tile (Bamboo, Circle, Character)
    for suit in range(3):  # 0=Bamboo, 1=Circle, 2=Character
        for value in range(1, 10):  # 1-9
            for _copy in range(4):
                var tile = Tile.new(Tile.TileType.SUIT, value, suit)
                asset_manager.set_tile_texture(tile)
                all_tiles.append(tile)
    
    # Create 4 copies of each honor tile (winds and dragons)
    for honor in range(7):  # 0-3=Winds, 4-6=Dragons
        for _copy in range(4):
            var tile = Tile.new(Tile.TileType.HONOR, -1, honor)
            asset_manager.set_tile_texture(tile)
            all_tiles.append(tile)
    
    # Create 1 copy of each bonus tile (seasons and flowers)
    for bonus in range(8):  # 0-3=Seasons, 4-7=Flowers
        var tile = Tile.new(Tile.TileType.BONUS, -1, bonus)
        asset_manager.set_tile_texture(tile)
        all_tiles.append(tile)
    
    return all_tiles

# Create the wall (shuffled tiles for drawing)
func create_wall() -> Array[Tile]:
    # Make sure we have tiles
    if all_tiles.is_empty():
        create_complete_set()
    
    # Copy all tiles to the wall
    wall = all_tiles.duplicate()
    
    # Shuffle the wall
    shuffle_wall()
    
    # Emit signal with the new wall count
    wall_created.emit(wall.size())
    
    return wall

# Shuffle the wall
func shuffle_wall():
    # Fisher-Yates shuffle algorithm
    var n = wall.size()
    for i in range(n - 1, 0, -1):
        var j = randi() % (i + 1)
        var temp = wall[i]
        wall[i] = wall[j]
        wall[j] = temp

# Draw a tile from the wall
func draw_tile() -> Tile:
    if wall.is_empty():
        wall_empty.emit()
        return null
    
    return wall.pop_back()

# Draw multiple tiles from the wall
func draw_tiles(count: int) -> Array[Tile]:
    var drawn: Array[Tile] = []
    
    for _i in range(count):
        var tile = draw_tile()
        if tile:
            drawn.append(tile)
        else:
            # Wall is empty
            break
    
    return drawn

# Distribute initial tiles to players (13 tiles per player in Sichuan rules)
func distribute_initial_tiles(player_count: int) -> Array:
    var player_hands = []
    
    # Always recreate wall to ensure we have enough tiles for all players
    create_wall()
    
    # Initialize player hands array
    for _i in range(player_count):
        player_hands.append([])
    
    # In Sichuan Mahjong, each player starts with 13 tiles
    for player_index in range(player_count):
        var tiles = draw_tiles(13)
        player_hands[player_index] = tiles
        tiles_distributed.emit(player_index, tiles)
    
    return player_hands

# Get the current size of the wall
func get_wall_size() -> int:
    return wall.size()

# Get the asset manager
func get_asset_manager() -> TileAssetManager:
    return asset_manager

# Change the size of all tile textures
func change_tile_size(new_size: int):
    asset_manager.change_tile_size(new_size)
    
    # Update textures for all existing tiles
    for tile in all_tiles:
        asset_manager.set_tile_texture(tile)

# Get all tiles of a specific type
func get_tiles_by_type(type: int) -> Array[Tile]:
    var result: Array[Tile] = []
    
    for tile in all_tiles:
        if tile.type == type:
            result.append(tile)
    
    return result

# Get all suit tiles
func get_suit_tiles() -> Array[Tile]:
    return get_tiles_by_type(Tile.TileType.SUIT)

# Get all honor tiles
func get_honor_tiles() -> Array[Tile]:
    return get_tiles_by_type(Tile.TileType.HONOR)

# Get all bonus tiles
func get_bonus_tiles() -> Array[Tile]:
    return get_tiles_by_type(Tile.TileType.BONUS)
