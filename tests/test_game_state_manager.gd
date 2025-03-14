extends Node

@onready var state_label = $VBoxContainer/StateLabel
@onready var game_state_manager = $GameStateManager

# Reference to buttons
@onready var menu_button = $VBoxContainer/ButtonsContainer/MenuButton
@onready var waiting_button = $VBoxContainer/ButtonsContainer/WaitingButton
@onready var setup_button = $VBoxContainer/ButtonsContainer/SetupButton
@onready var playing_button = $VBoxContainer/ButtonsContainer/PlayingButton
@onready var scoring_button = $VBoxContainer/ButtonsContainer/ScoringButton
@onready var game_over_button = $VBoxContainer/ButtonsContainer/GameOverButton

func _ready():
	# Connect signals
	game_state_manager.connect("state_changed", Callable(self, "_on_state_changed"))
	
	# Connect button signals
	menu_button.connect("pressed", Callable(self, "_on_menu_button_pressed"))
	waiting_button.connect("pressed", Callable(self, "_on_waiting_button_pressed"))
	setup_button.connect("pressed", Callable(self, "_on_setup_button_pressed"))
	playing_button.connect("pressed", Callable(self, "_on_playing_button_pressed"))
	scoring_button.connect("pressed", Callable(self, "_on_scoring_button_pressed"))
	game_over_button.connect("pressed", Callable(self, "_on_game_over_button_pressed"))
	
	# Update state label initially
	_update_state_label()
	
	print("Game State Manager Test initialized")

@warning_ignore("unused_parameter")
func _on_state_changed(from_state, to_state):
	_update_state_label()

func _update_state_label():
	state_label.text = "Current State: " + game_state_manager.get_state_name(game_state_manager.get_current_state())

# Button callbacks
func _on_menu_button_pressed():
	game_state_manager.change_state(game_state_manager.GameState.MENU)
	
func _on_waiting_button_pressed():
	game_state_manager.change_state(game_state_manager.GameState.WAITING)
	
func _on_setup_button_pressed():
	game_state_manager.change_state(game_state_manager.GameState.SETUP)
	
func _on_playing_button_pressed():
	game_state_manager.change_state(game_state_manager.GameState.PLAYING)
	
func _on_scoring_button_pressed():
	game_state_manager.change_state(game_state_manager.GameState.SCORING)
	
func _on_game_over_button_pressed():
	game_state_manager.change_state(game_state_manager.GameState.GAME_OVER)
