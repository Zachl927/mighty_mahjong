extends Node
class_name TileAssetManager

# Constants for tile sizes available
const TILE_SIZES = [64, 96, 128, 618]
const DEFAULT_SIZE = 128
const DEFAULT_TILESET_PATH = "res://assets/mahjong-tileset"

# Textures cache organized by size and tile ID
var textures = {}
var current_size = DEFAULT_SIZE

func _init(size: int = DEFAULT_SIZE):
	# Validate and set the tile size
	if size in TILE_SIZES:
		current_size = size
	else:
		push_warning("Invalid tile size %d, using default size %d" % [size, DEFAULT_SIZE])
		current_size = DEFAULT_SIZE
	
	# Preload all textures for the selected size
	preload_textures()

# Preload all textures for current size for efficient access
func preload_textures():
	textures.clear()
	textures[current_size] = {}
	
	# Base path for the current tile size
	var base_path = "%s/%d/fulltiles" % [DEFAULT_TILESET_PATH, current_size]
	
	# Load suit tiles (Bamboo, Circle, Pinyin)
	_preload_suit_tiles(base_path, Tile.SuitType.BAMBOO, "bamboo", 9)
	_preload_suit_tiles(base_path, Tile.SuitType.CIRCLE, "circle", 9)
	_preload_suit_tiles(base_path, Tile.SuitType.PINYIN, "pinyin", 9)  # Pinyin tiles
	
	# For Sichuan mahjong, we don't need the honor and bonus tiles
	# as it only uses the three suits (bamboo, circle, and pinyin/wan)

# Helper function to preload suit tiles
func _preload_suit_tiles(base_path: String, suit_type: int, file_prefix: String, count: int):
	for i in range(1, count + 1):
		var path = "%s/%s%d.png" % [base_path, file_prefix, i]
		var suit_name = Tile.SuitType.keys()[suit_type]
		var tile_id = "SUIT_%s_%d" % [suit_name, i]
		textures[current_size][tile_id] = load(path)

# Get texture for a specific tile
func get_texture(tile: Tile) -> Texture2D:
	if not textures.has(current_size) or not textures[current_size].has(tile.tile_id):
		push_error("Texture not found for tile: %s" % tile.tile_id)
		return null
	
	return textures[current_size][tile.tile_id]

# Set texture for a specific tile
func set_tile_texture(tile: Tile):
	if not textures.has(current_size) or not textures[current_size].has(tile.tile_id):
		push_error("Texture not found for tile: %s" % tile.tile_id)
		return
	
	# Set the tile's texture
	tile.texture = textures[current_size][tile.tile_id]
	
	# Set the image path based on current size
	var base_path = "%s/%d/fulltiles" % [DEFAULT_TILESET_PATH, current_size]
	
	if tile.type == Tile.TileType.SUIT:
		var prefix
		match tile.suit_type:
			Tile.SuitType.BAMBOO: prefix = "bamboo"
			Tile.SuitType.CIRCLE: prefix = "circle"
			Tile.SuitType.PINYIN: prefix = "pinyin"
		
		tile.image_path = "%s/%s%d.png" % [base_path, prefix, tile.value]

# Change tile size dynamically
func change_tile_size(new_size: int):
	if new_size in TILE_SIZES:
		if not textures.has(new_size):
			# Cache current size
			var previous_size = current_size
			current_size = new_size
			preload_textures()
			# Restore current size
			current_size = previous_size
		
		current_size = new_size
	else:
		push_warning("Invalid tile size %d, sizes available: %s" % [new_size, TILE_SIZES])

# Get the back of tile texture
func get_back_texture() -> Texture2D:
	var back_path = "%s/%d/tile.png" % [DEFAULT_TILESET_PATH, current_size]
	return load(back_path)

func get_current_size() -> int:
	return current_size
