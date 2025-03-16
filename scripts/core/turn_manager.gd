extends Node
class_name TurnManager

# Import required classes
const StateSync = preload("res://scripts/networking/state_sync.gd")

# Enum for turn phases
enum TurnPhase {
	WAITING,        # Waiting for game to start
	DRAW_PHASE,     # Current player should draw a tile
	DISCARD_PHASE,  # Current player should discard a tile
	CLAIM_PHASE,    # Other players can claim the discarded tile
	CLAIM_WAIT,     # Waiting for claim responses from other players
	GAME_OVER       # Game has ended
}

# Enum for player actions
enum PlayerAction {
	DRAW,       # Draw a tile from the wall
	DISCARD,    # Discard a tile from hand
	PENG,       # Claim discarded tile for a triplet
	GANG,       # Claim discarded tile for a set of four or add to triplet
	SKIP_CLAIM, # Skip the opportunity to claim
	WIN         # Declare a winning hand
}

# For a multiplayer game, this determines how long (in seconds) other players have
# to decide if they want to claim a discarded tile
const DEFAULT_CLAIM_WINDOW_SECONDS = 5.0

# Dependencies
var game_rules: GameRules
var network_manager: NetworkManager
var state_sync: StateSync

# Turn state properties
var current_phase: int = TurnPhase.WAITING
var current_player_index: int = -1
var player_ids: Array = []
var waiting_for_claims: bool = false
var claim_timer: float = 0.0
var last_discarded_tile = null
var last_action_player_id: int = -1
var player_responses: Dictionary = {}

# Signals
signal turn_changed(player_id: int, turn_phase: int)
signal action_performed(player_id: int, action: int, action_data: Dictionary) 
signal claim_window_started(seconds: float, tile)
signal claim_window_updated(seconds_remaining: float)
signal claim_window_ended()

# Initialize the turn manager with required dependencies
func initialize(p_game_rules: GameRules, p_network_manager: NetworkManager, p_state_sync: StateSync) -> void:
	game_rules = p_game_rules
	network_manager = p_network_manager
	state_sync = p_state_sync
	
	# Connect to necessary signals from game_rules
	game_rules.turn_changed.connect(_on_game_rules_turn_changed)
	game_rules.action_validated.connect(_on_action_validated)
	game_rules.game_over.connect(_on_game_over)
	
	# Connect to state sync signals
	state_sync.sync_action_received.connect(_on_sync_action_received)
	
	_reset_state()
	print("TurnManager initialized")

# Set up a new game with the specified player IDs
func setup_game(p_player_ids: Array) -> void:
	player_ids = p_player_ids.duplicate()
	_reset_state()
	
	# Initialize the game rules with player IDs
	game_rules.initialize_game(player_ids)
	
	# If we're the host, send the game setup synchronization
	if network_manager.is_host():
		var setup_data = {
			"player_ids": player_ids
		}
		state_sync.send_game_action(StateSync.GameAction.GAME_START, setup_data)

# Start the game - can only be called by host
func start_game() -> void:
	if !network_manager.is_host():
		push_error("Only host can start the game")
		return
	
	print("TurnManager: Starting game with players: " + str(player_ids))
	
	current_phase = TurnPhase.DRAW_PHASE
	current_player_index = 0
	
	# Start the game in game_rules
	game_rules.start_game()
	
	# First, make sure all clients know about the game state
	# This includes who is in the game
	var game_setup_data = {
		"player_ids": player_ids.duplicate()
	}
	state_sync.send_game_action(StateSync.GameAction.GAME_START, game_setup_data)
	
	# Then, send the round start info
	var start_data = {
		"first_player_index": current_player_index
	}
	state_sync.send_game_action(StateSync.GameAction.ROUND_START, start_data)
	
	# Finally, emit local turn change signal
	emit_signal("turn_changed", get_current_player_id(), current_phase)
	print("TurnManager: Game started!")

# Handle a player action
func perform_action(player_id: int, action: int, action_data: Dictionary = {}) -> bool:
	# Validate if this is a legal action
	if !_is_action_valid(player_id, action, action_data):
		return false
	
	# Process the action based on type
	match action:
		PlayerAction.DRAW:
			_handle_draw_action(player_id, action_data)
		
		PlayerAction.DISCARD:
			_handle_discard_action(player_id, action_data)
		
		PlayerAction.PENG:
			_handle_peng_action(player_id, action_data)
		
		PlayerAction.GANG:
			_handle_gang_action(player_id, action_data)
		
		PlayerAction.SKIP_CLAIM:
			_handle_skip_claim_action(player_id)
		
		PlayerAction.WIN:
			_handle_win_action(player_id, action_data)
	
	emit_signal("action_performed", player_id, action, action_data)
	return true

# Process per-frame updates (especially for claim timer)
func _process(delta: float) -> void:
	if waiting_for_claims and claim_timer > 0:
		claim_timer -= delta
		emit_signal("claim_window_updated", claim_timer)
		
		if claim_timer <= 0:
			_end_claim_window()

# Get the current player ID
func get_current_player_id() -> int:
	if player_ids.size() == 0 or current_player_index < 0 or current_player_index >= player_ids.size():
		return -1
	return player_ids[current_player_index]

# Get the current phase
func get_current_phase() -> int:
	return current_phase

# Check if a player can perform a specific action
func can_perform_action(player_id: int, action: int, action_data: Dictionary = {}) -> bool:
	return _is_action_valid(player_id, action, action_data)

# Reset the internal state
func _reset_state() -> void:
	current_phase = TurnPhase.WAITING
	current_player_index = -1
	waiting_for_claims = false
	claim_timer = 0.0
	last_discarded_tile = null
	last_action_player_id = -1
	player_responses.clear()

# Validate if an action is valid given the current state
func _is_action_valid(player_id: int, action: int, action_data: Dictionary) -> bool:
	# Game over check
	if current_phase == TurnPhase.GAME_OVER:
		return false
	
	# Basic validity checks based on phase
	match current_phase:
		TurnPhase.WAITING:
			return false
			
		TurnPhase.DRAW_PHASE:
			# Only current player can draw
			if action != PlayerAction.DRAW or player_id != get_current_player_id():
				return false
		
		TurnPhase.DISCARD_PHASE:
			# Only current player can discard or declare win from drawn tile
			if player_id != get_current_player_id():
				return false
				
			if action != PlayerAction.DISCARD and action != PlayerAction.WIN:
				return false
				
			# For discard, make sure they have the tile
			if action == PlayerAction.DISCARD and not action_data.has("tile"):
				return false
		
		TurnPhase.CLAIM_PHASE, TurnPhase.CLAIM_WAIT:
			# Only other players can claim
			if player_id == last_action_player_id:
				return false
				
			# Only claim actions are valid
			if action != PlayerAction.PENG and action != PlayerAction.GANG and action != PlayerAction.WIN and action != PlayerAction.SKIP_CLAIM:
				return false
				
			# If we're past the claim window, no more claims
			if current_phase == TurnPhase.CLAIM_PHASE and claim_timer <= 0:
				return false
				
			# If already responded, can't respond again
			if player_responses.has(player_id):
				return false
	
	# Additional validation through game_rules for most actions
	var tile = action_data.get("tile", null)
	var player_hand = action_data.get("player_hand", null)
	
	match action:
		PlayerAction.DRAW:
			return game_rules.validate_draw(player_id, player_hand)
			
		PlayerAction.DISCARD:
			return game_rules.validate_discard(player_id, tile, player_hand)
			
		PlayerAction.PENG:
			return game_rules.validate_peng(player_id, last_discarded_tile, player_hand)
			
		PlayerAction.GANG:
			return game_rules.validate_gang(player_id, last_discarded_tile, player_hand)
			
		PlayerAction.WIN:
			if current_phase == TurnPhase.DISCARD_PHASE:
				# Win after drawing
				return game_rules.validate_win(player_id, null, player_hand)
			else:
				# Win from claiming discard
				return game_rules.validate_win(player_id, last_discarded_tile, player_hand)
				
		PlayerAction.SKIP_CLAIM:
			# Skip is always valid during claim phase
			return true
	
	return false

# Handle a draw action
func _handle_draw_action(player_id: int, action_data: Dictionary) -> void:
	# Update local state
	current_phase = TurnPhase.DISCARD_PHASE
	
	# Send network message if we're the host or if this is our action
	if network_manager.is_host() or player_id == network_manager.get_my_id():
		state_sync.send_game_action(StateSync.GameAction.DRAW_TILE, {
			"player_id": player_id
		})

# Handle a discard action
func _handle_discard_action(player_id: int, action_data: Dictionary) -> void:
	var tile = action_data.get("tile")
	if not tile:
		return
	
	# Update local state
	last_discarded_tile = tile
	last_action_player_id = player_id
	current_phase = TurnPhase.CLAIM_PHASE
	waiting_for_claims = true
	claim_timer = DEFAULT_CLAIM_WINDOW_SECONDS
	player_responses.clear()
	
	# Send network message
	if network_manager.is_host() or player_id == network_manager.get_my_id():
		state_sync.send_game_action(StateSync.GameAction.DISCARD_TILE, {
			"player_id": player_id,
			"tile": tile
		})
	
	# Start the claim window
	emit_signal("claim_window_started", DEFAULT_CLAIM_WINDOW_SECONDS, tile)

# Handle a peng action
func _handle_peng_action(player_id: int, action_data: Dictionary) -> void:
	# Record the response
	player_responses[player_id] = {"action": PlayerAction.PENG}
	
	# If we're the host, resolve this immediately
	if network_manager.is_host():
		_resolve_claim(player_id, PlayerAction.PENG)
	else:
		# Send claim message to host
		state_sync.send_game_action(StateSync.GameAction.CLAIM_TILE, {
			"player_id": player_id,
			"claim_type": PlayerAction.PENG
		})

# Handle a gang action
func _handle_gang_action(player_id: int, action_data: Dictionary) -> void:
	# Record the response
	player_responses[player_id] = {"action": PlayerAction.GANG}
	
	# If we're the host, resolve this immediately
	if network_manager.is_host():
		_resolve_claim(player_id, PlayerAction.GANG)
	else:
		# Send claim message to host
		state_sync.send_game_action(StateSync.GameAction.CLAIM_TILE, {
			"player_id": player_id,
			"claim_type": PlayerAction.GANG
		})

# Handle a skip claim action
func _handle_skip_claim_action(player_id: int) -> void:
	# Record the response
	player_responses[player_id] = {"action": PlayerAction.SKIP_CLAIM}
	
	# If we're the host, check if all players have responded
	if network_manager.is_host():
		_check_all_claims_received()
	else:
		# Send skip message to host
		state_sync.send_game_action(StateSync.GameAction.CLAIM_TILE, {
			"player_id": player_id,
			"claim_type": PlayerAction.SKIP_CLAIM
		})

# Handle a win action
func _handle_win_action(player_id: int, action_data: Dictionary) -> void:
	# Update state
	current_phase = TurnPhase.GAME_OVER
	
	# If winning from claim, record the response
	if waiting_for_claims:
		player_responses[player_id] = {"action": PlayerAction.WIN}
		
	# If we're the host or if this is our action
	if network_manager.is_host() or player_id == network_manager.get_my_id():
		# Send win message
		state_sync.send_game_action(StateSync.GameAction.WIN_HAND, {
			"player_id": player_id,
			"from_discard": waiting_for_claims,
			"score": action_data.get("score", 0)
		})
	
	# If we're the host and this is from a claim, resolve immediately
	if network_manager.is_host() and waiting_for_claims:
		_resolve_claim(player_id, PlayerAction.WIN)

# End the claim window
func _end_claim_window() -> void:
	waiting_for_claims = false
	claim_timer = 0
	
	# If we're the host, move to the next player
	if network_manager.is_host():
		_advance_to_next_player()
	
	emit_signal("claim_window_ended")

# Advance to the next player's turn
func _advance_to_next_player() -> void:
	current_player_index = (current_player_index + 1) % player_ids.size()
	current_phase = TurnPhase.DRAW_PHASE
	
	# If we're the host, send turn change message
	if network_manager.is_host():
		state_sync.send_game_action(StateSync.GameAction.SYNC_GAME_STATE, {
			"current_player_index": current_player_index,
			"current_phase": current_phase
		})
	
	emit_signal("turn_changed", get_current_player_id(), current_phase)

# Resolve a claim from a player
func _resolve_claim(player_id: int, claim_type: int) -> void:
	# Only host should resolve claims
	if !network_manager.is_host():
		return
	
	waiting_for_claims = false
	claim_timer = 0
	
	match claim_type:
		PlayerAction.PENG:
			# Player forms a Peng and next phase is discard
			current_player_index = player_ids.find(player_id)
			current_phase = TurnPhase.DISCARD_PHASE
		
		PlayerAction.GANG:
			# Player forms a Gang and gets to draw from the back
			current_player_index = player_ids.find(player_id)
			current_phase = TurnPhase.DRAW_PHASE
		
		PlayerAction.WIN:
			# Player wins the hand
			current_phase = TurnPhase.GAME_OVER
	
	# Send state update
	state_sync.send_game_action(StateSync.GameAction.SYNC_GAME_STATE, {
		"current_player_index": current_player_index,
		"current_phase": current_phase
	})
	
	emit_signal("turn_changed", get_current_player_id(), current_phase)
	emit_signal("claim_window_ended")

# Check if all players have responded to the claim opportunity
func _check_all_claims_received() -> void:
	if !network_manager.is_host():
		return
	
	var expected_responses = player_ids.size() - 1  # Exclude the discarder
	
	# If we have all responses and they're all skips, move to next player
	if player_responses.size() >= expected_responses:
		var all_skipped = true
		
		for player_id in player_responses:
			if player_responses[player_id].get("action") != PlayerAction.SKIP_CLAIM:
				all_skipped = false
				break
		
		if all_skipped:
			_end_claim_window()

# Signal handlers

func _on_game_rules_turn_changed(player_id: int, turn_state: int) -> void:
	# Map game_rules turn state to our turn phase
	var phase = TurnPhase.WAITING
	
	match turn_state:
		GameRules.TurnState.WAITING:
			phase = TurnPhase.WAITING
		GameRules.TurnState.DRAW_PHASE:
			phase = TurnPhase.DRAW_PHASE
		GameRules.TurnState.DISCARD_PHASE:
			phase = TurnPhase.DISCARD_PHASE
		GameRules.TurnState.CLAIM_PHASE:
			phase = TurnPhase.CLAIM_PHASE
		GameRules.TurnState.GAME_OVER:
			phase = TurnPhase.GAME_OVER
	
	current_phase = phase
	current_player_index = player_ids.find(player_id)
	
	emit_signal("turn_changed", player_id, phase)

func _on_action_validated(player_id: int, action_type: int, is_valid: bool, message: String) -> void:
	# We can use this to provide feedback about action validity
	if !is_valid:
		print("Invalid action from player ", player_id, ": ", message)

func _on_game_over(winner_id: int, score: int) -> void:
	current_phase = TurnPhase.GAME_OVER
	emit_signal("turn_changed", winner_id, current_phase)

func _on_sync_action_received(action_type: int, action_data: Dictionary) -> void:
	# Process actions received from the network
	print("TurnManager received sync action: " + str(action_type) + " with data: " + str(action_data))
	
	match action_type:
		StateSync.GameAction.GAME_START:
			print("TurnManager handling GAME_START action")
			# Initialize with synchronized player data
			if action_data.has("player_ids"):
				player_ids = action_data.player_ids.duplicate()
				print("Setting player_ids to: " + str(player_ids))
				game_rules.initialize_game(player_ids)
				print("Game rules initialized with players")
			else:
				print("Warning: GAME_START action missing player_ids")
		
		StateSync.GameAction.ROUND_START:
			print("TurnManager handling ROUND_START action")
			# Set initial turn from host's data
			if action_data.has("first_player_index"):
				current_player_index = action_data.first_player_index
				current_phase = TurnPhase.DRAW_PHASE
				print("Setting current player to index: " + str(current_player_index) + ", phase: DRAW_PHASE")
				emit_signal("turn_changed", get_current_player_id(), current_phase)
			else:
				print("Warning: ROUND_START action missing first_player_index")
		
		StateSync.GameAction.SYNC_GAME_STATE:
			print("TurnManager handling SYNC_GAME_STATE action")
			# Update local turn state from host's data
			if action_data.has("current_player_index") and action_data.has("current_phase"):
				current_player_index = action_data.current_player_index
				current_phase = action_data.current_phase
				print("Updated state - player index: " + str(current_player_index) + ", phase: " + str(current_phase))
				
				if waiting_for_claims:
					waiting_for_claims = false
					claim_timer = 0
					emit_signal("claim_window_ended")
					print("Ended claim window due to state sync")
				
				# Always emit the turn changed signal to update UI
				emit_signal("turn_changed", get_current_player_id(), current_phase)
			else:
				print("Warning: SYNC_GAME_STATE missing player index or phase info") 