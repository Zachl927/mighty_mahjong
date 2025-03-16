extends Node

# This script is used to debug class accessibility issues

func _ready():
	print("=== DEBUG: CLASS ACCESSIBILITY TEST ===")
	
	# Check if the Tile class is accessible
	print("Checking Tile class...")
	if ClassDB.class_exists("Tile"):
		print("SUCCESS: Tile class is globally registered")
	else:
		print("WARNING: Tile class is not globally registered")
	
	# Check if the TurnManager class is accessible
	print("Checking TurnManager class...")
	if ClassDB.class_exists("TurnManager"):
		print("SUCCESS: TurnManager class is globally registered")
	else:
		print("WARNING: TurnManager class is not globally registered")
	
	# Check if the StateSync class is accessible
	print("Checking StateSync class...")
	if ClassDB.class_exists("StateSync"):
		print("SUCCESS: StateSync class is globally registered")
	else:
		print("WARNING: StateSync class is not globally registered")
	
	# Check Tile enums
	print("Checking Tile enums...")
	if "TileType" in Tile:
		print("SUCCESS: TileType enum found in Tile")
		print("Values: ", Tile.TileType.keys())
	else:
		print("WARNING: TileType enum not found in Tile")
	
	if "SuitType" in Tile:
		print("SUCCESS: SuitType enum found in Tile")
		print("Values: ", Tile.SuitType.keys())
	else:
		print("WARNING: SuitType enum not found in Tile")
	
	# Try to create a Tile
	print("Trying to create a Tile...")
	var tile_success = false
	var tile = null
	
	# Try with parameters first
	print("Attempting to create Tile with parameters...")
	
	# Using a try-except block in GDScript 2.0 syntax
	var had_error = false
	
	# Try with parameters
	tile = Tile.new(Tile.TileType.SUIT, 5, Tile.SuitType.BAMBOO)
	if tile != null:
		print("SUCCESS: Created Tile with parameters")
		tile_success = true
	else:
		print("ERROR: Failed to create Tile with parameters")
	
	# If that didn't work, try without parameters
	if not tile_success:
		print("Attempting to create Tile without parameters...")
		# We know from the error that Tile.new() requires at least one parameter
		# So we'll skip this test
		print("SKIPPED: Tile constructor requires parameters")
	
	# Check if we successfully created a Tile
	if tile_success:
		print("Tile properties: type=", tile.type, ", suit_type=", tile.suit_type, ", value=", tile.value)
	
	print("=== DEBUG END ===") 