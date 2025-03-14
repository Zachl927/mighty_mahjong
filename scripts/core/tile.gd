extends Resource
class_name Tile

# Tile type enums
enum TileType {SUIT, HONOR, BONUS}
enum SuitType {BAMBOO, CIRCLE, CHARACTER}
enum HonorType {WIND_EAST, WIND_SOUTH, WIND_WEST, WIND_NORTH, DRAGON_RED, DRAGON_GREEN, DRAGON_WHITE}
enum BonusType {SEASON_SPRING, SEASON_SUMMER, SEASON_AUTUMN, SEASON_WINTER, 
			   FLOWER_PLUM, FLOWER_ORCHID, FLOWER_CHRYSANTHEMUM, FLOWER_BAMBOO}

# Tile properties
var type: int
var suit_type: int = -1
var honor_type: int = -1
var bonus_type: int = -1
var value: int = -1
var image_path: String
var texture: Texture2D

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
		
		TileType.HONOR:
			honor_type = p_sub_type
			# No numeric value for honors, using honor type as identifier
			tile_id = "HONOR_%s" % HonorType.keys()[honor_type]
			
		TileType.BONUS:
			bonus_type = p_sub_type
			# No numeric value for bonus tiles, using bonus type as identifier
			tile_id = "BONUS_%s" % BonusType.keys()[bonus_type]
	
	# Image path and texture will be set by the TileAssetManager

func get_tile_name() -> String:
	match type:
		TileType.SUIT:
			var suit_name = SuitType.keys()[suit_type].capitalize()
			return "%s %d" % [suit_name, value]
		
		TileType.HONOR:
			return HonorType.keys()[honor_type].replace("_", " ").capitalize()
			
		TileType.BONUS:
			return BonusType.keys()[bonus_type].replace("_", " ").capitalize()
	
	return "Unknown Tile"

func get_display_name() -> String:
	return get_tile_name()

func is_suit() -> bool:
	return type == TileType.SUIT
	
func is_honor() -> bool:
	return type == TileType.HONOR
	
func is_bonus() -> bool:
	return type == TileType.BONUS

# Compare two tiles to check if they're the same type and value
func matches(other_tile: Tile) -> bool:
	if type != other_tile.type:
		return false
		
	match type:
		TileType.SUIT:
			return suit_type == other_tile.suit_type and value == other_tile.value
		TileType.HONOR:
			return honor_type == other_tile.honor_type
		TileType.BONUS:
			return bonus_type == other_tile.bonus_type
			
	return false

# Used for sorting tiles in a hand
func get_sort_value() -> int:
	match type:
		TileType.SUIT:
			# Sort by suit type (0-2) and then by value (1-9)
			return suit_type * 100 + value
		TileType.HONOR:
			# Honor tiles come after suit tiles
			return 300 + honor_type
		TileType.BONUS:
			# Bonus tiles come last
			return 400 + bonus_type
	
	return 999  # Unknown tile types sorted last
