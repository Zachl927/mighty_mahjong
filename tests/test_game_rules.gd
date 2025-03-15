extends Node

# References to UI elements
@onready var test_status_label = $VBoxContainer/StatusLabel
@onready var test_output = $VBoxContainer/TestOutput
@onready var run_tests_button = $VBoxContainer/ButtonsContainer/RunTestsButton

# References to game components
@onready var game_rules = $GameRules
@onready var tile_manager = $TileManager

# Test variables
var player_hands = []
var test_results = []
var total_tests = 0
var passed_tests = 0

func _ready():
	# Connect signals
	run_tests_button.connect("pressed", Callable(self, "_on_run_tests_button_pressed"))
	game_rules.connect("action_validated", Callable(self, "_on_action_validated"))
	
	# Initialize 4 player hands for testing
	for i in range(4):
		var player_hand = PlayerHand.new()
		player_hand.player_id = i
		player_hands.append(player_hand)
	
	print("Game Rules Test initialized")

func _on_run_tests_button_pressed():
	clear_test_results()
	run_game_rules_tests()

func clear_test_results():
	test_results.clear()
	test_output.text = ""
	total_tests = 0
	passed_tests = 0
	test_status_label.text = "Running tests..."

func add_test_result(test_name, passed, message = ""):
	total_tests += 1
	if passed:
		passed_tests += 1
		test_results.append("[✓] " + test_name + (": " + message if message else ""))
	else:
		test_results.append("[✗] " + test_name + (": " + message if message else ""))
	
	update_test_output()

func update_test_output():
	test_output.text = ""
	for result in test_results:
		test_output.text += result + "\n"
	
	test_status_label.text = "Tests: " + str(passed_tests) + "/" + str(total_tests) + " passed"
	test_status_label.add_theme_color_override("font_color", Color(0, 1, 0) if passed_tests == total_tests else Color(1, 0, 0))

func run_game_rules_tests():
	# Reset test data
	for hand in player_hands:
		hand.clear_hand()
	
	# Run individual tests
	test_suit_restriction()
	test_action_validation()
	test_peng_validation()
	test_gang_validation()
	test_winning_conditions()
	test_scoring()

func test_suit_restriction():
	# Test 1: Valid 2-suit hand (TIAO and WAN)
	var hand1 = player_hands[0]
	add_test_tiles(hand1, [
		create_test_tile(GameRules.TileType.TIAO, 1),
		create_test_tile(GameRules.TileType.TIAO, 2),
		create_test_tile(GameRules.TileType.TIAO, 3),
		create_test_tile(GameRules.TileType.WAN, 1),
		create_test_tile(GameRules.TileType.WAN, 2)
	])
	var result1 = game_rules.is_valid_suit_restriction(hand1.get_all_tiles())
	add_test_result("2-suit hand passes restriction", result1)
	
	# Test 2: Invalid 3-suit hand (TIAO, TONG, and WAN)
	var hand2 = player_hands[1]
	add_test_tiles(hand2, [
		create_test_tile(GameRules.TileType.TIAO, 1),
		create_test_tile(GameRules.TileType.TONG, 2),
		create_test_tile(GameRules.TileType.WAN, 3)
	])
	var result2 = game_rules.is_valid_suit_restriction(hand2.get_all_tiles())
	add_test_result("3-suit hand fails restriction", !result2)
	
	# Clear hands after testing
	hand1.clear_hand()
	hand2.clear_hand()

func test_action_validation():
	# Test draw validation
	var hand = player_hands[0]
	hand.clear_hand()
	
	# Valid draw (hand not full)
	for i in range(12):  # Add 12 tiles (less than max)
		hand.add_tile(create_test_tile(GameRules.TileType.TIAO, 1))
	
	var draw_result = game_rules.validate_action(0, GameRules.ActionType.DRAW, null, hand)
	add_test_result("Draw with non-full hand", draw_result)
	
	# Invalid draw (hand at max capacity)
	for i in range(2):  # Add 2 more tiles to reach max
		hand.add_tile(create_test_tile(GameRules.TileType.TIAO, 1))
	
	draw_result = game_rules.validate_action(0, GameRules.ActionType.DRAW, null, hand)
	add_test_result("Draw with full hand", !draw_result)
	
	# Test discard validation
	var discard_tile = create_test_tile(GameRules.TileType.TIAO, 1)
	hand.add_tile(discard_tile)
	
	var discard_result = game_rules.validate_action(0, GameRules.ActionType.DISCARD, discard_tile, hand)
	add_test_result("Discard tile in hand", discard_result)
	
	var missing_tile = create_test_tile(GameRules.TileType.TONG, 9)  # Not in hand
	discard_result = game_rules.validate_action(0, GameRules.ActionType.DISCARD, missing_tile, hand)
	add_test_result("Discard tile not in hand", !discard_result)
	
	hand.clear_hand()

func test_peng_validation():
	var hand = player_hands[0]
	hand.clear_hand()
	
	# Add 2 matching tiles to hand
	var tile_type = GameRules.TileType.TIAO
	var tile_value = 5
	hand.add_tile(create_test_tile(tile_type, tile_value))
	hand.add_tile(create_test_tile(tile_type, tile_value))
	
	# Test valid peng (with 2 matching tiles in hand)
	var peng_tile = create_test_tile(tile_type, tile_value)
	var peng_result = game_rules.validate_action(0, GameRules.ActionType.PENG, peng_tile, hand)
	add_test_result("Peng with 2 matching tiles", peng_result)
	
	# Test invalid peng (without matching tiles)
	var non_matching_tile = create_test_tile(GameRules.TileType.TONG, 1)
	peng_result = game_rules.validate_action(0, GameRules.ActionType.PENG, non_matching_tile, hand)
	add_test_result("Peng with no matching tiles", !peng_result)
	
	hand.clear_hand()

func test_gang_validation():
	var hand = player_hands[0]
	hand.clear_hand()
	
	# Add 3 matching tiles to hand
	var tile_type = GameRules.TileType.WAN
	var tile_value = 3
	for i in range(3):
		hand.add_tile(create_test_tile(tile_type, tile_value))
	
	# Test valid gang (with 3 matching tiles in hand)
	var gang_tile = create_test_tile(tile_type, tile_value)
	var gang_result = game_rules.validate_action(0, GameRules.ActionType.GANG, gang_tile, hand)
	add_test_result("Gang with 3 matching tiles", gang_result)
	
	# Test invalid gang (without matching tiles)
	var non_matching_tile = create_test_tile(GameRules.TileType.TONG, 1)
	gang_result = game_rules.validate_action(0, GameRules.ActionType.GANG, non_matching_tile, hand)
	add_test_result("Gang with no matching tiles", !gang_result)
	
	hand.clear_hand()

func test_winning_conditions():
	# This would be a more complex test with various winning patterns
	# For now, we'll use simplified test cases
	
	# Test seven pairs winning condition
	var hand = player_hands[0]
	hand.clear_hand()
	
	# Add 7 pairs of tiles (all pairs, 2 suits)
	add_test_tiles(hand, [
		create_test_tile(GameRules.TileType.TIAO, 1),
		create_test_tile(GameRules.TileType.TIAO, 1),
		create_test_tile(GameRules.TileType.TIAO, 2),
		create_test_tile(GameRules.TileType.TIAO, 2),
		create_test_tile(GameRules.TileType.TIAO, 3),
		create_test_tile(GameRules.TileType.TIAO, 3),
		create_test_tile(GameRules.TileType.TIAO, 4),
		create_test_tile(GameRules.TileType.TIAO, 4),
		create_test_tile(GameRules.TileType.WAN, 1),
		create_test_tile(GameRules.TileType.WAN, 1),
		create_test_tile(GameRules.TileType.WAN, 2),
		create_test_tile(GameRules.TileType.WAN, 2),
		create_test_tile(GameRules.TileType.WAN, 3),
		create_test_tile(GameRules.TileType.WAN, 3)
	])
	
	# Since we haven't fully implemented the winning condition logic yet,
	# we'll add a placeholder test result
	add_test_result("Seven pairs win condition", true, "Placeholder test - actual validation needed")
	
	hand.clear_hand()

func test_scoring():
	# This would test various scoring scenarios
	# For now, we'll use simplified test cases
	
	# Test basic scoring
	var hand = player_hands[0]
	hand.clear_hand()
	
	# Add some test tiles for scoring
	add_test_tiles(hand, [
		create_test_tile(GameRules.TileType.TIAO, 1),
		create_test_tile(GameRules.TileType.TIAO, 1),
		create_test_tile(GameRules.TileType.TIAO, 1)
	])
	
	# Since we haven't fully implemented the scoring logic yet,
	# we'll add a placeholder test result
	add_test_result("Basic scoring", true, "Placeholder test - actual calculation needed")
	
	hand.clear_hand()

# Helper function to create a test tile
func create_test_tile(type, value):
	# Need to pass type (SUIT) as first parameter to Tile constructor
	var tile = Tile.new(Tile.TileType.SUIT, value, type)
	return tile

# Helper function to add multiple test tiles to a hand
func add_test_tiles(hand, tiles):
	for tile in tiles:
		hand.add_tile(tile)

# Signal handler for action validation
func _on_action_validated(player_id, action_type, is_valid, message):
	print("Action validated: ", player_id, " ", action_type, " ", is_valid, " ", message)
