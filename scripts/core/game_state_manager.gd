extends Node

# Enum for game states
enum GameState {
	MENU,     # Main menu
	WAITING,  # Waiting for players
	SETUP,    # Setting up game
	PLAYING,  # Active gameplay
	SCORING,  # Calculating scores
	GAME_OVER # End of game
}

# Current game state
var current_state: int = GameState.MENU

# Game data
var player_count: int = 0
var max_players: int = 4
var host_mode: bool = false
var game_id: String = ""
var players = []
var current_round: int = 0
var max_rounds: int = 16  # Standard Mahjong is usually 16 rounds (4 rounds for each wind)

# Signals
signal state_changed(from_state, to_state)
signal player_joined(player_info)
signal player_left(player_id)
signal game_started()
signal round_started(round_number)
signal round_ended(round_number, scores)
signal game_ended(final_scores)

func _ready():
	print("Game State Manager initialized")
	_initialize_default_state()

# Initialize the default state
func _initialize_default_state() -> void:
	# Reset all game data to default
	player_count = 0
	max_players = 4
	host_mode = false
	game_id = ""
	players = []
	current_round = 0
	max_rounds = 16

# Change the game state with proper transition logic
func change_state(new_state: int) -> void:
	if new_state != current_state:
		var old_state = current_state
		
		# Execute exit actions for the old state
		_exit_state(old_state)
		
		# Update state
		current_state = new_state
		
		# Execute enter actions for the new state
		_enter_state(current_state)
		
		# Emit signal for listeners
		emit_signal("state_changed", old_state, current_state)
		print("Game state changed from %s to %s" % [get_state_name(old_state), get_state_name(current_state)])

# Actions to perform when exiting a state
func _exit_state(state: int) -> void:
	match state:
		GameState.MENU:
			pass
		GameState.WAITING:
			pass
		GameState.SETUP:
			pass
		GameState.PLAYING:
			pass
		GameState.SCORING:
			pass
		GameState.GAME_OVER:
			pass

# Actions to perform when entering a state
func _enter_state(state: int) -> void:
	match state:
		GameState.MENU:
			pass
		GameState.WAITING:
			pass
		GameState.SETUP:
			pass
		GameState.PLAYING:
			emit_signal("round_started", current_round)
		GameState.SCORING:
			pass
		GameState.GAME_OVER:
			pass

# Get the current state
func get_current_state() -> int:
	return current_state

# Get the name of a state (for debugging)
func get_state_name(state: int) -> String:
	match state:
		GameState.MENU:
			return "MENU"
		GameState.WAITING:
			return "WAITING"
		GameState.SETUP:
			return "SETUP"
		GameState.PLAYING:
			return "PLAYING"
		GameState.SCORING:
			return "SCORING"
		GameState.GAME_OVER:
			return "GAME_OVER"
		_:
			return "UNKNOWN"

# Helper methods for common state transitions

# Start a new game session (host or join)
func start_session(is_host: bool) -> void:
	host_mode = is_host
	change_state(GameState.WAITING)

# Add a player to the game
func add_player(player_info: Dictionary) -> void:
	if player_count < max_players and current_state == GameState.WAITING:
		players.append(player_info)
		player_count += 1
		emit_signal("player_joined", player_info)
		print("Player added: %s" % player_info.get("name", "Unknown"))

# Remove a player from the game
func remove_player(player_id: String) -> void:
	for i in range(players.size()):
		if players[i].get("id") == player_id:
			var player_info = players[i]
			players.remove_at(i)
			player_count -= 1
			emit_signal("player_left", player_id)
			print("Player removed: %s" % player_info.get("name", "Unknown"))
			break

# Start the game when all players are ready
func start_game() -> void:
	if player_count >= 2 and current_state == GameState.WAITING:
		change_state(GameState.SETUP)
		# Additional setup logic would go here
		current_round = 1
		change_state(GameState.PLAYING)
		emit_signal("game_started")

# End the current round and proceed to scoring
func end_round(scores: Dictionary) -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.SCORING)
		emit_signal("round_ended", current_round, scores)
		
		# After scoring, check if this was the last round
		if current_round >= max_rounds:
			change_state(GameState.GAME_OVER)
			emit_signal("game_ended", scores)
		else:
			# Prepare for next round
			current_round += 1
			change_state(GameState.PLAYING)

# Reset the game to menu
func return_to_menu() -> void:
	change_state(GameState.MENU)
	_initialize_default_state()

# Start a new game after game over
func new_game() -> void:
	if current_state == GameState.GAME_OVER:
		_initialize_default_state()
		change_state(GameState.MENU)
