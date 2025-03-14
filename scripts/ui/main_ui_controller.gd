extends Control

# Node references
@onready var game_state_manager = $"/root/GameStateManager" if has_node("/root/GameStateManager") else null
@onready var main_menu = $MainMenu
@onready var game_screen = $GameScreen
@onready var host_game_button = $MainMenu/ButtonsContainer/HostGameButton
@onready var join_game_button = $MainMenu/ButtonsContainer/JoinGameButton
@onready var settings_button = $MainMenu/ButtonsContainer/SettingsButton
@onready var quit_button = $MainMenu/ButtonsContainer/QuitButton
@onready var menu_button = $GameScreen/GameArea/TopBar/MenuButton
@onready var game_info_label = $GameScreen/GameArea/TopBar/GameInfoLabel
@onready var action_buttons = $GameScreen/GameArea/ActionButtons.get_children()

# Chat components
@onready var chat_input = $GameScreen/ChatArea/ChatInput/LineEdit
@onready var send_button = $GameScreen/ChatArea/ChatInput/SendButton
@onready var chat_log = $GameScreen/ChatArea/ChatLog

func _ready():
	print("Main UI Controller initialized")
	
	# Connect game state manager signals if available
	if game_state_manager:
		game_state_manager.state_changed.connect(_on_game_state_changed)
		game_state_manager.player_joined.connect(_on_player_joined)
		game_state_manager.player_left.connect(_on_player_left)
		game_state_manager.game_started.connect(_on_game_started)
		game_state_manager.round_started.connect(_on_round_started)
		game_state_manager.round_ended.connect(_on_round_ended)
		game_state_manager.game_ended.connect(_on_game_ended)
	else:
		print("Warning: GameStateManager not found, using local state")
		# Create a local instance for testing
		var gsm_script = load("res://scripts/core/game_state_manager.gd")
		if gsm_script:
			game_state_manager = gsm_script.new()
			add_child(game_state_manager)
			game_state_manager.state_changed.connect(_on_game_state_changed)
	
	# Connect UI signals
	host_game_button.pressed.connect(_on_host_game_pressed)
	join_game_button.pressed.connect(_on_join_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	send_button.pressed.connect(_on_send_message_pressed)
	
	# Connect action buttons
	for button in action_buttons:
		button.pressed.connect(_on_action_button_pressed.bind(button.name))
	
	# Initially show main menu only
	_update_ui_for_state(game_state_manager.GameState.MENU)

# Update UI based on game state
func _update_ui_for_state(state: int) -> void:
	match state:
		game_state_manager.GameState.MENU:
			main_menu.visible = true
			game_screen.visible = false
		game_state_manager.GameState.WAITING, game_state_manager.GameState.SETUP, \
		game_state_manager.GameState.PLAYING, game_state_manager.GameState.SCORING, \
		game_state_manager.GameState.GAME_OVER:
			main_menu.visible = false
			game_screen.visible = true
			_update_game_screen_for_state(state)

# Update game screen based on game state
func _update_game_screen_for_state(state: int) -> void:
	# Update game info label
	var state_name = game_state_manager.get_state_name(state)
	var round_info = ""
	
	if state == game_state_manager.GameState.PLAYING:
		var current_round = game_state_manager.current_round
		# Determine wind based on round (simplified)
		var winds = ["East", "South", "West", "North"]
		var wind = winds[((current_round - 1) / 4) % 4]
		round_info = "Round: %d | %s Wind" % [current_round, wind]
	
	game_info_label.text = state_name + (": " + round_info if round_info else "")
	
	# Enable/disable appropriate action buttons based on game state
	for button in action_buttons:
		button.disabled = state != game_state_manager.GameState.PLAYING
	
	# Add chat message to indicate state change
	add_chat_message("System", "Game state changed to " + state_name)

# Add a message to the chat log
func add_chat_message(sender: String, message: String) -> void:
	var timestamp = Time.get_time_string_from_system()
	chat_log.text += "\n[%s] %s: %s" % [timestamp, sender, message]
	chat_log.scroll_to_line(chat_log.get_line_count())

# Button signal handlers
func _on_host_game_pressed() -> void:
	if game_state_manager:
		game_state_manager.host_mode = true
		game_state_manager.change_state(game_state_manager.GameState.WAITING)
		add_chat_message("System", "Hosting a new game. Waiting for players...")

func _on_join_game_pressed() -> void:
	if game_state_manager:
		game_state_manager.host_mode = false
		game_state_manager.change_state(game_state_manager.GameState.WAITING)
		add_chat_message("System", "Joining a game. Connecting...")
		
		# Simulate a player joining (for testing only)
		game_state_manager.add_player({"id": "1", "name": "Player 1"})
		game_state_manager.add_player({"id": "2", "name": "Player 2"})
		game_state_manager.add_player({"id": "3", "name": "Player 3"})

func _on_settings_pressed() -> void:
	print("Settings pressed - Not implemented yet")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_menu_button_pressed() -> void:
	if game_state_manager:
		game_state_manager.return_to_menu()

func _on_send_message_pressed() -> void:
	var message = chat_input.text.strip_edges()
	if message:
		add_chat_message("You", message)
		chat_input.text = ""

func _on_action_button_pressed(button_name: String) -> void:
	print("Action button pressed: ", button_name)
	
	# Handle action button logic based on button name
	match button_name:
		"DrawButton":
			add_chat_message("System", "You drew a tile")
		"DiscardButton":
			add_chat_message("System", "Select a tile to discard")
		"PongButton":
			add_chat_message("System", "Pong claimed")
		"KongButton":
			add_chat_message("System", "Kong claimed")
		"ChowButton":
			add_chat_message("System", "Chow claimed")
		"MahjongButton":
			add_chat_message("System", "Mahjong! You won the round!")
			if game_state_manager:
				game_state_manager.end_round({"winner": "You", "points": 100})

# Game state manager signal handlers
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	print("Game state changed from %s to %s" % [
		game_state_manager.get_state_name(from_state),
		game_state_manager.get_state_name(to_state)
	])
	_update_ui_for_state(to_state)

func _on_player_joined(player_info: Dictionary) -> void:
	print("Player joined: ", player_info)
	add_chat_message("System", "Player joined: " + player_info.get("name", "Unknown"))
	
	# If we have enough players, enable start game button (not implemented yet)
	if game_state_manager.player_count >= 2:
		add_chat_message("System", "Enough players have joined. Starting game soon...")
		await get_tree().create_timer(2.0).timeout
		if game_state_manager.current_state == game_state_manager.GameState.WAITING:
			game_state_manager.start_game()

func _on_player_left(player_id: String) -> void:
	print("Player left: ", player_id)
	add_chat_message("System", "A player has left the game")

func _on_game_started() -> void:
	print("Game started")
	add_chat_message("System", "Game has started")

func _on_round_started(round_number: int) -> void:
	print("Round started: ", round_number)
	add_chat_message("System", "Round %d has started" % round_number)

func _on_round_ended(round_number: int, scores: Dictionary) -> void:
	print("Round ended: ", round_number, " with scores: ", scores)
	add_chat_message("System", "Round %d has ended" % round_number)
	
	# Display scores
	for player in scores.keys():
		add_chat_message("System", "%s scored %d points" % [player, scores[player]])

func _on_game_ended(final_scores: Dictionary) -> void:
	print("Game ended with final scores: ", final_scores)
	add_chat_message("System", "Game has ended")
	
	# Display final scores
	for player in final_scores.keys():
		add_chat_message("System", "%s: %d points" % [player, final_scores[player]])
