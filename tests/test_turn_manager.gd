extends Control

# References to nodes in the scene
@onready var game_rules = $GameRules
@onready var network_manager = $NetworkManager
@onready var state_sync = $StateSync
@onready var turn_manager = $TurnManager

# UI elements
@onready var status_label = $VBoxContainer/StatusLabel
@onready var host_button = $VBoxContainer/HBoxContainer/NetworkPanel/HostButton
@onready var join_button = $VBoxContainer/HBoxContainer/NetworkPanel/JoinButton
@onready var ip_address_edit = $VBoxContainer/HBoxContainer/NetworkPanel/IPAddressEdit
@onready var start_game_button = $VBoxContainer/HBoxContainer/GamePanel/StartGameButton
@onready var draw_tile_button = $VBoxContainer/HBoxContainer/GamePanel/DrawTileButton
@onready var discard_tile_button = $VBoxContainer/HBoxContainer/GamePanel/DiscardTileButton
@onready var peng_button = $VBoxContainer/HBoxContainer2/ClaimPanel/PengButton
@onready var gang_button = $VBoxContainer/HBoxContainer2/ClaimPanel/GangButton
@onready var skip_claim_button = $VBoxContainer/HBoxContainer2/ClaimPanel/SkipClaimButton
@onready var current_player_label = $VBoxContainer/HBoxContainer2/StatusPanel/CurrentPlayerLabel
@onready var current_phase_label = $VBoxContainer/HBoxContainer2/StatusPanel/CurrentPhaseLabel
@onready var claim_timer_label = $VBoxContainer/HBoxContainer2/StatusPanel/ClaimTimerLabel
@onready var event_log = $VBoxContainer/EventLog

# Test player IDs (simulated)
var test_player_ids = [1, 2, 3, 4]  # Simulated player IDs
var my_player_id = 1  # Default to player 1 (host)
var mock_tile = null  # For simulating tile actions

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize components
	_initialize_components()
	
	# Connect UI signals
	_connect_signals()
	
	# Set up initial UI state
	_update_ui_state()
	
	# Log initialization
	log_event("Test scene initialized")

# Initialize all components
func _initialize_components():
	# Create a mock tile for testing
	mock_tile = Tile.new(Tile.TileType.SUIT, 5, Tile.SuitType.BAMBOO)
	mock_tile.tile_id = "test_tile_1"
	
	# Set up network manager with test mode
	if network_manager.has_method("set_test_mode"):
		network_manager.set_test_mode(true)
	
	# Initialize state sync with dependencies
	if state_sync.has_method("initialize"):
		state_sync.initialize(network_manager, null, null, game_rules)
	
	# Initialize turn manager with dependencies
	if turn_manager.has_method("initialize"):
		turn_manager.initialize(game_rules, network_manager, state_sync)
		
		# Connect to turn manager signals
		if turn_manager.has_signal("turn_changed"):
			turn_manager.turn_changed.connect(_on_turn_changed)
		if turn_manager.has_signal("action_performed"):
			turn_manager.action_performed.connect(_on_action_performed)
		if turn_manager.has_signal("claim_window_started"):
			turn_manager.claim_window_started.connect(_on_claim_window_started)
		if turn_manager.has_signal("claim_window_updated"):
			turn_manager.claim_window_updated.connect(_on_claim_window_updated)
		if turn_manager.has_signal("claim_window_ended"):
			turn_manager.claim_window_ended.connect(_on_claim_window_ended)

# Connect UI signals to functions
func _connect_signals():
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	draw_tile_button.pressed.connect(_on_draw_tile_button_pressed)
	discard_tile_button.pressed.connect(_on_discard_tile_button_pressed)
	peng_button.pressed.connect(_on_peng_button_pressed)
	gang_button.pressed.connect(_on_gang_button_pressed)
	skip_claim_button.pressed.connect(_on_skip_claim_button_pressed)

# Update UI state based on current game state
func _update_ui_state():
	# Update game status labels
	var current_player_id = 0
	if turn_manager.has_method("get_current_player_id"):
		current_player_id = turn_manager.get_current_player_id()
	current_player_label.text = "Current Player: " + str(current_player_id)
	
	var phase_name = "Unknown"
	var current_phase = 0
	if turn_manager.has_method("get_current_phase"):
		current_phase = turn_manager.get_current_phase()
	
	# Use integer values directly since we know the enum values
	match current_phase:
		0:  # WAITING
			phase_name = "Waiting"
		1:  # DRAW_PHASE
			phase_name = "Draw Phase"
		2:  # DISCARD_PHASE
			phase_name = "Discard Phase"
		3:  # CLAIM_PHASE
			phase_name = "Claim Phase"
		4:  # CLAIM_WAIT
			phase_name = "Claim Wait"
		5:  # GAME_OVER
			phase_name = "Game Over"
	
	current_phase_label.text = "Current Phase: " + phase_name
	
	# Update button states based on current phase and player
	var is_my_turn = current_player_id == my_player_id
	
	var is_host = false
	if network_manager.has_method("is_host"):
		is_host = network_manager.is_host()
	
	start_game_button.disabled = current_phase != 0 or !is_host  # 0 = WAITING
	draw_tile_button.disabled = current_phase != 1 or !is_my_turn  # 1 = DRAW_PHASE
	discard_tile_button.disabled = current_phase != 2 or !is_my_turn  # 2 = DISCARD_PHASE
	
	var can_claim = current_phase == 3 and current_player_id != my_player_id  # 3 = CLAIM_PHASE
	peng_button.disabled = !can_claim
	gang_button.disabled = !can_claim
	skip_claim_button.disabled = !can_claim

# Process function for updating UI elements that need regular updates
func _process(delta):
	# Safely check for properties
	var waiting_for_claims = false
	var claim_timer = 0.0
	
	if turn_manager and "waiting_for_claims" in turn_manager:
		waiting_for_claims = turn_manager.waiting_for_claims
		
	if turn_manager and "claim_timer" in turn_manager:
		claim_timer = turn_manager.claim_timer
	
	if waiting_for_claims and claim_timer > 0:
		claim_timer_label.text = "Claim Timer: %.1f" % claim_timer
	else:
		claim_timer_label.text = "Claim Timer: 0.0"

# Log an event to the event log
func log_event(message: String):
	var timestamp = Time.get_time_string_from_system()
	event_log.text += "\n[%s] %s" % [timestamp, message]

# Button handlers

func _on_host_button_pressed():
	if network_manager.has_method("create_host"):
		network_manager.create_host()
	my_player_id = 1  # Host is always player 1
	
	# Set up test players (in a real game, players would join over the network)
	if turn_manager.has_method("setup_game"):
		turn_manager.setup_game(test_player_ids)
	
	log_event("Hosted game with test players: " + str(test_player_ids))
	_update_ui_state()

func _on_join_button_pressed():
	var ip = ip_address_edit.text
	if network_manager.has_method("join_host"):
		network_manager.join_host(ip)
	my_player_id = 2  # For testing, join as player 2
	
	log_event("Joined game at " + ip + " as player " + str(my_player_id))
	_update_ui_state()

func _on_start_game_button_pressed():
	if turn_manager.has_method("start_game"):
		turn_manager.start_game()
	log_event("Game started")
	_update_ui_state()

func _on_draw_tile_button_pressed():
	var action_data = {
		"player_hand": null  # In a real game, this would be the actual player hand
	}
	
	var success = false
	if turn_manager.has_method("perform_action"):
		success = turn_manager.perform_action(my_player_id, 0, action_data)  # 0 = DRAW
	
	if success:
		log_event("Drew a tile")
	else:
		log_event("Failed to draw a tile")
	
	_update_ui_state()

func _on_discard_tile_button_pressed():
	var action_data = {
		"tile": mock_tile,
		"player_hand": null  # In a real game, this would be the actual player hand
	}
	
	var success = false
	if turn_manager.has_method("perform_action"):
		success = turn_manager.perform_action(my_player_id, 1, action_data)  # 1 = DISCARD
	
	if success:
		log_event("Discarded tile: " + str(mock_tile.suit_type) + " " + str(mock_tile.value))
	else:
		log_event("Failed to discard tile")
	
	_update_ui_state()

func _on_peng_button_pressed():
	var action_data = {
		"player_hand": null  # In a real game, this would be the actual player hand
	}
	
	var success = false
	if turn_manager.has_method("perform_action"):
		success = turn_manager.perform_action(my_player_id, 2, action_data)  # 2 = PENG
	
	if success:
		log_event("Claimed Peng")
	else:
		log_event("Failed to claim Peng")
	
	_update_ui_state()

func _on_gang_button_pressed():
	var action_data = {
		"player_hand": null  # In a real game, this would be the actual player hand
	}
	
	var success = false
	if turn_manager.has_method("perform_action"):
		success = turn_manager.perform_action(my_player_id, 3, action_data)  # 3 = GANG
	
	if success:
		log_event("Claimed Gang")
	else:
		log_event("Failed to claim Gang")
	
	_update_ui_state()

func _on_skip_claim_button_pressed():
	var success = false
	if turn_manager.has_method("perform_action"):
		success = turn_manager.perform_action(my_player_id, 4)  # 4 = SKIP_CLAIM
	
	if success:
		log_event("Skipped claim opportunity")
	else:
		log_event("Failed to skip claim")
	
	_update_ui_state()

# Turn manager signal handlers

func _on_turn_changed(player_id, turn_phase):
	log_event("Turn changed to player " + str(player_id) + " in phase " + str(turn_phase))
	_update_ui_state()

func _on_action_performed(player_id, action, action_data):
	var action_name = ""
	match action:
		0:  # DRAW
			action_name = "Draw"
		1:  # DISCARD
			action_name = "Discard"
		2:  # PENG
			action_name = "Peng"
		3:  # GANG
			action_name = "Gang"
		4:  # SKIP_CLAIM
			action_name = "Skip Claim"
		5:  # WIN
			action_name = "Win"
	
	log_event("Player " + str(player_id) + " performed action: " + action_name)
	_update_ui_state()

func _on_claim_window_started(seconds, tile):
	log_event("Claim window started for " + str(seconds) + " seconds")
	_update_ui_state()

func _on_claim_window_updated(seconds_remaining):
	# We don't log this to avoid spamming the log
	pass

func _on_claim_window_ended():
	log_event("Claim window ended")
	_update_ui_state() 