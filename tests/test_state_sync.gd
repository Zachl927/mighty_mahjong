extends Control

# Node references
@onready var network_manager = $NetworkManager
@onready var state_sync = $StateSync
@onready var game_state_manager = $GameStateManager

# Preload the StateSync script to get access to the enum
const StateSyncScript = preload("res://scripts/networking/state_sync.gd")

# UI references
@onready var status_label = $UI/MarginContainer/VBoxContainer/HeaderSection/StatusLabel
@onready var ip_input = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/IPInputContainer/IPInput
@onready var port_input = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/PortInputContainer/PortInput
@onready var player_name_input = $UI/MarginContainer/VBoxContainer/NameSection/PlayerNameInput
@onready var update_name_button = $UI/MarginContainer/VBoxContainer/NameSection/UpdateNameButton
@onready var host_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/ButtonsContainer/HostButton
@onready var join_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/ButtonsContainer/JoinButton
@onready var disconnect_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/ButtonsContainer/DisconnectButton
@onready var player_list = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/Players/PlayerList
@onready var state_info_display = $UI/MarginContainer/VBoxContainer/MainContent/RightSection/GameStateDisplay/StateInfoDisplay
@onready var log_text = $UI/MarginContainer/VBoxContainer/MainContent/RightSection/LogPanel/LogText

# Game control buttons
@onready var start_game_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/GameControls/StartGameButton
@onready var draw_tile_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/GameControls/GameActionButtonsContainer/DrawTileButton
@onready var discard_tile_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/GameControls/GameActionButtonsContainer/DiscardTileButton
@onready var claim_tile_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/GameControls/GameActionButtonsContainer/ClaimTileButton
@onready var win_hand_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/GameControls/GameActionButtonsContainer/WinHandButton
@onready var force_sync_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/GameControls/ForceSyncButton

# Mock gameplay components for testing
var tile_manager: TileManager
var game_rules: GameRules
var test_tiles = [] # Sample tiles for testing

# Called when the node enters the scene tree
func _ready():
	# Connect UI button signals
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	disconnect_button.pressed.connect(_on_disconnect_button_pressed)
	update_name_button.pressed.connect(_on_update_name_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	draw_tile_button.pressed.connect(_on_draw_tile_button_pressed)
	discard_tile_button.pressed.connect(_on_discard_tile_button_pressed)
	claim_tile_button.pressed.connect(_on_claim_tile_button_pressed)
	win_hand_button.pressed.connect(_on_win_hand_button_pressed)
	force_sync_button.pressed.connect(_on_force_sync_button_pressed)
	
	# Connect network manager signals
	network_manager.network_event.connect(_on_network_event)
	network_manager.player_info_updated.connect(_on_player_info_updated)
	network_manager.connection_successful.connect(_on_connection_successful)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.host_started.connect(_on_host_started)
	network_manager.disconnected.connect(_on_disconnected)
	network_manager.game_error.connect(_on_game_error)
	
	# Connect game state manager signals
	game_state_manager.state_changed.connect(_on_game_state_changed)
	
	# Set initial UI states
	_update_game_controls(false) # Disable game controls initially
	
	# Initialize mock gameplay components for testing
	_init_mock_components()
	
	# Initialize the state sync component
	state_sync.initialize(network_manager, game_state_manager, tile_manager, game_rules)
	
	# Connect state sync signals
	state_sync.sync_completed.connect(_on_sync_completed)
	state_sync.sync_action_received.connect(_on_sync_action_received)
	state_sync.sync_error.connect(_on_sync_error)
	
	# Add initial log message
	add_log_message("Test initialized. Use the controls to test state synchronization.")
	
	# Update game state display
	update_state_display()

# Initialize mock gameplay components for testing
func _init_mock_components():
	# Create a tile manager with 128px tiles
	tile_manager = TileManager.new(128)
	
	# Create the complete set of tiles
	tile_manager.create_complete_set()
	
	# Create a game rules instance
	game_rules = GameRules.new()
	
	# Create some test tiles
	_create_test_tiles()

# Create some test tiles for use in actions
func _create_test_tiles():
	# Create wall for drawing tiles
	tile_manager.create_wall()
	
	# Draw 5 sample tiles for testing
	for i in range(5):
		var tile = tile_manager.draw_tile()
		if tile:
			test_tiles.append(tile)

# UI button handlers
func _on_host_button_pressed():
	var port = int(port_input.text)
	var result = network_manager.create_host(port)
	if result == OK:
		add_log_message("Started hosting on port " + str(port))
	else:
		add_log_message("Failed to host: Error " + str(result))

func _on_join_button_pressed():
	var address = ip_input.text
	var port = int(port_input.text)
	var result = network_manager.join_host(address, port)
	if result == OK:
		add_log_message("Joining host at " + address + ":" + str(port))
	else:
		add_log_message("Failed to join: Error " + str(result))

func _on_disconnect_button_pressed():
	network_manager.disconnect_from_network()
	add_log_message("Disconnected from network")

func _on_update_name_button_pressed():
	var name = player_name_input.text.strip_edges()
	if name:
		network_manager.update_my_info({"name": name})
		add_log_message("Updated player name to: " + name)

func _on_start_game_button_pressed():
	if network_manager.is_host():
		# Create action data for starting a game
		var action_data = {
			"game_id": "test_game_" + str(Time.get_unix_time_from_system()),
			"players": network_manager.get_all_players()
		}
		
		# Send the game start action
		state_sync.send_game_action(StateSyncScript.GameAction.GAME_START, action_data)
		
		# Start the game locally
		game_state_manager.change_state(game_state_manager.GameState.SETUP)
		await get_tree().create_timer(0.5).timeout
		game_state_manager.change_state(game_state_manager.GameState.PLAYING)
		
		add_log_message("Game started by host")
	else:
		add_log_message("Only the host can start the game")

func _on_draw_tile_button_pressed():
	# Draw a tile from our mock tile manager
	var tile = tile_manager.draw_tile()
	
	if tile:
		var action_data = {
			"player_id": network_manager.get_my_id(),
			"tile": tile,
			"wall_remaining": tile_manager.get_wall_size()
		}
		
		state_sync.send_game_action(StateSyncScript.GameAction.DRAW_TILE, action_data)
		add_log_message("Drew a tile: " + tile.get_tile_name())
	else:
		add_log_message("No more tiles to draw!")

func _on_discard_tile_button_pressed():
	# Use a test tile from our collection, or draw a new one if needed
	var tile = null
	
	if test_tiles.size() > 0:
		tile = test_tiles.pop_front()
	else:
		tile = tile_manager.draw_tile()
	
	if tile:
		var action_data = {
			"player_id": network_manager.get_my_id(),
			"tile": tile
		}
		
		state_sync.send_game_action(StateSyncScript.GameAction.DISCARD_TILE, action_data)
		add_log_message("Discarded a tile: " + tile.get_tile_name())
	else:
		add_log_message("No tile to discard!")

func _on_claim_tile_button_pressed():
	# Use a random claim type
	var claim_types = ["pong", "kong", "chow"]
	var claim_type = claim_types[randi() % claim_types.size()]
	
	var action_data = {
		"player_id": network_manager.get_my_id(),
		"claim_type": claim_type
	}
	
	state_sync.send_game_action(StateSyncScript.GameAction.CLAIM_TILE, action_data)
	add_log_message("Claimed tile with: " + claim_type)

func _on_win_hand_button_pressed():
	# Generate a random score for testing
	var score = randi_range(20, 100)
	
	var action_data = {
		"player_id": network_manager.get_my_id(),
		"score": score
	}
	
	state_sync.send_game_action(StateSyncScript.GameAction.WIN_HAND, action_data)
	add_log_message("Won the hand with score: " + str(score))

func _on_force_sync_button_pressed():
	if network_manager.is_host():
		state_sync.send_full_game_state_sync()
		add_log_message("Sent full game state sync to all clients")
	else:
		add_log_message("Only the host can force a game state sync")

# Network event handlers
func _on_network_event(event_type, data):
	add_log_message("Network event: " + str(event_type) + ", Data: " + str(data))
	update_state_display()

func _on_player_info_updated(player_id, info):
	add_log_message("Player updated [ID: " + str(player_id) + "]: " + str(info))
	_update_player_list()

func _on_connection_successful():
	add_log_message("Successfully connected to host")
	status_label.text = "Status: Connected (Client)"
	_update_game_controls(true)
	_update_player_list()

func _on_connection_failed(error):
	add_log_message("Connection failed: " + error)
	status_label.text = "Status: Connection Failed"
	_update_game_controls(false)

func _on_host_started():
	add_log_message("Host started")
	status_label.text = "Status: Hosting"
	_update_game_controls(true)
	_update_player_list()

func _on_disconnected(reason):
	add_log_message("Disconnected: " + reason)
	status_label.text = "Status: Disconnected"
	_update_game_controls(false)
	_reset_player_list()

func _on_game_error(error):
	add_log_message("Game error: " + error)

# Game state event handlers
func _on_game_state_changed(from_state, to_state):
	var from_name = game_state_manager.get_state_name(from_state)
	var to_name = game_state_manager.get_state_name(to_state)
	add_log_message("Game state changed: " + from_name + " -> " + to_name)
	update_state_display()

# State sync event handlers
func _on_sync_completed():
	add_log_message("Game state synchronization completed")
	update_state_display()

func _on_sync_action_received(action_type, action_data):
	var action_name = StateSyncScript.GameAction.keys()[action_type]
	add_log_message("Received action: " + action_name)
	update_state_display()

func _on_sync_error(error_message):
	add_log_message("Sync error: " + error_message)

# Helper functions
func add_log_message(message):
	var timestamp = Time.get_time_string_from_system()
	log_text.text += "\n[" + timestamp + "] " + message
	
	# Auto-scroll to the bottom
	log_text.scroll_vertical = log_text.get_line_count()

func update_state_display():
	# Get the game state data to display
	var state_data = state_sync.game_state_data
	
	# Format the state data as text
	var text = ""
	text += "Current Game State: " + game_state_manager.get_state_name(game_state_manager.current_state) + "\n"
	text += "Game ID: " + str(state_data.get("game_id", "")) + "\n"
	text += "Current Round: " + str(state_data.get("current_round", 0)) + "\n"
	text += "Player Index: " + str(state_data.get("current_player_index", 0)) + "\n"
	text += "Turn State: " + str(state_data.get("current_turn_state", 0)) + "\n"
	text += "Wall Remaining: " + str(state_data.get("wall_remaining", 0)) + "\n"
	
	# Last action
	var last_action = state_data.get("last_action", {})
	if not last_action.is_empty():
		text += "\nLast Action:\n"
		text += "  Type: " + str(last_action.get("type", "")) + "\n"
		text += "  Player: " + str(last_action.get("player_id", "")) + "\n"
		
		# If there's a tile in the last action, show its details
		if last_action.has("tile") and last_action.tile != null:
			var tile = last_action.tile
			if tile is Tile:
				text += "  Tile: " + tile.get_tile_name() + "\n"
			else:
				text += "  Tile: " + str(tile) + "\n"
	
	# Update the display
	state_info_display.text = text

func _update_player_list():
	player_list.clear()
	
	var players = network_manager.get_all_players()
	
	if players.is_empty():
		player_list.add_item("No players connected")
	else:
		for player_id in players:
			var player_info = players[player_id]
			var player_name = player_info.get("name", "Unknown")
			var is_ready = player_info.get("ready", false)
			var status = " (Ready)" if is_ready else ""
			
			# Mark host and current player
			var prefix = ""
			if player_id == 1:
				prefix = "[HOST] "
			if player_id == network_manager.get_my_id():
				prefix += "[YOU] "
			
			player_list.add_item(prefix + player_name + status)

func _reset_player_list():
	player_list.clear()
	player_list.add_item("No players connected")

func _update_game_controls(enabled: bool):
	start_game_button.disabled = not enabled
	draw_tile_button.disabled = not enabled
	discard_tile_button.disabled = not enabled
	claim_tile_button.disabled = not enabled
	win_hand_button.disabled = not enabled
	force_sync_button.disabled = not enabled 