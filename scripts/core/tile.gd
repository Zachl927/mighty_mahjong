extends Resource
class_name Tile

# Tile type enums
enum TileType {SUIT}
enum SuitType {BAMBOO, CIRCLE, PINYIN}

# Tile properties
var type: int
var suit_type: int = -1
var value: int = -1
var image_path: String
var texture: Texture2D

# Special properties
var from_back_end: bool = false  # Indicates if this tile was drawn from the back of the wall (for Gang)

# For identification and comparison
var tile_id: String

func _init(p_type: int, p_value: int = -1, p_sub_type: int = -1):
	type = p_type
	
	match type:
		TileType.SUIT:
			suit_type = p_sub_type
			value = p_value
			# Create ID like "SUIT_BAMBOO_1"
			var suit_name = SuitType.keys()[suit_type]
			tile_id = "SUIT_%s_%d" % [suit_name, value]
	
	# Image path and texture will be set by the TileAssetManager

func get_tile_name() -> String:
	match type:
		TileType.SUIT:
			var suit_name = SuitType.keys()[suit_type].capitalize()
			return "%s %d" % [suit_name, value]
	
	return "Unknown Tile"

func get_display_name() -> String:
	return get_tile_name()

func is_suit() -> bool:
	return type == TileType.SUIT

# Check if this is a bonus tile (Sichuan mahjong doesn't use bonus tiles)
func is_bonus() -> bool:
	return false  # No bonus tiles in Sichuan mahjong

# Compare two tiles to check if they're the same type and value
func matches(other_tile: Tile) -> bool:
	if type != other_tile.type:
		return false
		
	match type:
		TileType.SUIT:
			return suit_type == other_tile.suit_type and value == other_tile.value
			
	return false

# Used for sorting tiles in a hand
func get_sort_value() -> int:
	match type:
		TileType.SUIT:
			# Sort by suit type (0-2) and then by value (1-9)
			return suit_type * 100 + value
	
	return 999  # Unknown tile types sorted last
