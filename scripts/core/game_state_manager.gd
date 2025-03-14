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

# Signal for state changes
signal state_changed(from_state, to_state)

func _ready():
	print("Game State Manager initialized")

# Change the game state
func change_state(new_state: int) -> void:
	if new_state != current_state:
		var old_state = current_state
		current_state = new_state
		emit_signal("state_changed", old_state, current_state)
		print("Game state changed from %s to %s" % [get_state_name(old_state), get_state_name(current_state)])

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
