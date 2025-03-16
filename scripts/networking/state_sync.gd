extends Node
class_name StateSync

# Dependencies
var network_manager: NetworkManager
var game_state_manager: Node  # Using Node type for loose coupling
var tile_manager: TileManager
var game_rules: GameRules

# Sync data structure - used to track what needs to be synchronized
var game_state_data: Dictionary = {
	"game_id": "",
	"current_state": 0,
	"players": [],
	"current_round": 0,
	"current_player_index": 0,
	"current_turn_state": 0,
	"wall_remaining": 0,
	"last_action": {},
	"last_discarded_tile": null
}

# Game action types (these correspond to network messages)
enum GameAction {
	GAME_START,
	ROUND_START,
	DRAW_TILE,
	DISCARD_TILE,
	CLAIM_TILE,
	FORM_SET,
	SYNC_GAME_STATE,
	WIN_HAND
}

# Signals
signal sync_completed()
signal sync_action_received(action_type: int, action_data: Dictionary)
signal sync_error(error_message: String)

# Initialize with required dependencies
func initialize(p_network_manager: NetworkManager, p_game_state_manager: Node, 
				p_tile_manager: TileManager, p_game_rules: GameRules) -> void:
	network_manager = p_network_manager
	game_state_manager = p_game_state_manager
	tile_manager = p_tile_manager
	game_rules = p_game_rules
	
	# Connect to network manager signal for game actions
	if network_manager != null:
		if network_manager.has_signal("network_event"):
			network_manager.network_event.connect(_on_network_event)
		else:
			push_warning("NetworkManager does not have 'network_event' signal")
	else:
		push_warning("NetworkManager dependency is null in StateSync")
	
	# Connect to game state manager signals
	if game_state_manager != null:
		if game_state_manager.has_signal("state_changed"):
			game_state_manager.state_changed.connect(_on_game_state_changed)
		else:
			push_warning("GameStateManager does not have 'state_changed' signal")
		
		if game_state_manager.has_signal("round_started"):
			game_state_manager.round_started.connect(_on_round_started)
		else:
			push_warning("GameStateManager does not have 'round_started' signal")
		
		if game_state_manager.has_signal("round_ended"):
			game_state_manager.round_ended.connect(_on_round_ended)
		else:
			push_warning("GameStateManager does not have 'round_ended' signal")
	else:
		push_warning("GameStateManager dependency is null in StateSync")
	
	# Connect to game rules signals
	if game_rules != null:
		if game_rules.has_signal("turn_changed"):
			game_rules.turn_changed.connect(_on_turn_changed)
		else:
			push_warning("GameRules does not have 'turn_changed' signal")
		
		if game_rules.has_signal("game_over"):
			game_rules.game_over.connect(_on_game_over)
		else:
			push_warning("GameRules does not have 'game_over' signal")
	else:
		push_warning("GameRules dependency is null in StateSync")
	
	print("StateSync initialized with safe signal connections")

# Send a game action through the network manager
func send_game_action(action_type: int, action_data: Dictionary, reliable: bool = true) -> void:
	# Only send if we have a valid network manager
	if not network_manager:
		push_error("Cannot send game action: NetworkManager not initialized")
		return
	
	# Convert action type to string for network transmission
	var action_type_str = GameAction.keys()[action_type]
	print("Sending game action: " + action_type_str + " with data: " + str(action_data) + " (reliable: " + str(reliable) + ")")
	
	# If we're sending tile data, we need to serialize it first
	if action_data.has("tile") and action_data.tile is Tile:
		action_data.tile = _serialize_tile(action_data.tile)
	
	if action_data.has("tiles") and action_data.tiles is Array:
		var serialized_tiles = []
		for tile in action_data.tiles:
			if tile is Tile:
				serialized_tiles.append(_serialize_tile(tile))
			else:
				serialized_tiles.append(tile)
		action_data.tiles = serialized_tiles
	
	# Send the action through the network manager
	network_manager.send_game_action(action_type_str, action_data, reliable)
	print("Action sent to NetworkManager")

# Serialize a tile for network transmission
func _serialize_tile(tile: Tile) -> Dictionary:
	if not tile:
		return {}
	
	return {
		"type": tile.type,
		"value": tile.value,
		"suit_type": tile.suit_type,
		"tile_id": tile.tile_id,
		"from_back_end": tile.from_back_end
	}

# Deserialize a tile from network data
func _deserialize_tile(tile_data: Dictionary) -> Tile:
	if tile_data.is_empty():
		return null
	
	var tile = Tile.new(tile_data.type, tile_data.value, tile_data.suit_type)
	tile.tile_id = tile_data.tile_id
	tile.from_back_end = tile_data.from_back_end
	
	# Set the tile texture using the asset manager
	if tile_manager and tile_manager.get_asset_manager():
		tile_manager.get_asset_manager().set_tile_texture(tile)
	
	return tile

# Process a game action received from the network
func _process_game_action(action_type_str: String, action_data: Dictionary) -> void:
	# Convert the action type string back to an enum value
	var action_type = GameAction.get(action_type_str, -1)
	
	if action_type == -1:
		push_error("Unknown game action: " + action_type_str)
		sync_error.emit("Unknown game action received: " + action_type_str)
		return
	
	print("StateSync processing action: " + action_type_str + " (action type ID: " + str(action_type) + ")")
	
	# Deserialize tile data if present
	if action_data.has("tile") and action_data.tile is Dictionary:
		action_data.tile = _deserialize_tile(action_data.tile)
	
	if action_data.has("tiles") and action_data.tiles is Array:
		var deserialized_tiles = []
		for tile_data in action_data.tiles:
			if tile_data is Dictionary:
				deserialized_tiles.append(_deserialize_tile(tile_data))
			else:
				deserialized_tiles.append(tile_data)
		action_data.tiles = deserialized_tiles
	
	# Process the action based on its type
	match action_type:
		GameAction.GAME_START:
			print("Handling GAME_START action")
			_handle_game_start(action_data)
		
		GameAction.ROUND_START:
			print("Handling ROUND_START action")
			_handle_round_start(action_data)
		
		GameAction.DRAW_TILE:
			_handle_draw_tile(action_data)
		
		GameAction.DISCARD_TILE:
			_handle_discard_tile(action_data)
		
		GameAction.CLAIM_TILE:
			_handle_claim_tile(action_data)
		
		GameAction.FORM_SET:
			_handle_form_set(action_data)
		
		GameAction.SYNC_GAME_STATE:
			print("Handling SYNC_GAME_STATE action")
			_handle_sync_game_state(action_data)
		
		GameAction.WIN_HAND:
			_handle_win_hand(action_data)
	
	# Emit signal for the received action
	sync_action_received.emit(action_type, action_data)
	print("Emitted sync_action_received signal for action: " + action_type_str)

# Game action handlers

func _handle_game_start(action_data: Dictionary) -> void:
	print("_handle_game_start called with data: " + str(action_data))
	
	if network_manager.is_host():
		print("Host received GAME_START - ignoring as host initiated this")
		return  # Host initiated this, no need to process
	
	# Update game state with received data
	if action_data.has("game_id"):
		game_state_data.game_id = action_data.game_id
		print("Updated game_id to: " + action_data.game_id)
	
	if action_data.has("players"):
		game_state_data.players = action_data.players
		print("Updated players list to: " + str(action_data.players))
	
	# Transition game state to SETUP
	if game_state_manager != null:
		print("Transitioning game state to SETUP")
		game_state_manager.change_state(game_state_manager.GameState.SETUP)
	else:
		print("Cannot transition to SETUP state: GameStateManager is null")

func _handle_round_start(action_data: Dictionary) -> void:
	if network_manager.is_host():
		return  # Host initiated this, no need to process
	
	# Update local round data
	if action_data.has("round"):
		game_state_data.current_round = action_data.round
		game_state_manager.current_round = action_data.round
	
	# If initial tiles are provided, set them up
	if action_data.has("initial_tiles") and action_data.has("player_index"):
		var player_index = action_data.player_index
		var tiles = action_data.initial_tiles
		
		# TODO: Initialize player's hand with these tiles
	
	# Update wall remaining count
	if action_data.has("wall_remaining"):
		game_state_data.wall_remaining = action_data.wall_remaining
	
	# Transition game state to PLAYING
	game_state_manager.change_state(game_state_manager.GameState.PLAYING)

func _handle_draw_tile(action_data: Dictionary) -> void:
	# Handle a player drawing a tile
	var player_id = action_data.player_id
	var tile = action_data.tile
	
	# Update local game state
	game_state_data.last_action = {
		"type": "draw",
		"player_id": player_id,
		"tile": tile
	}
	
	# Update wall remaining count
	if action_data.has("wall_remaining"):
		game_state_data.wall_remaining = action_data.wall_remaining
	
	# If this is our draw, we need to add the tile to our hand
	if player_id == network_manager.get_my_id():
		# TODO: Add tile to player's hand
		pass

func _handle_discard_tile(action_data: Dictionary) -> void:
	# Handle a player discarding a tile
	var player_id = action_data.player_id
	var tile = action_data.tile
	
	# Update local game state
	game_state_data.last_action = {
		"type": "discard",
		"player_id": player_id,
		"tile": tile
	}
	
	game_state_data.last_discarded_tile = tile
	
	# TODO: Update discard pile with this tile

func _handle_claim_tile(action_data: Dictionary) -> void:
	# Handle a player claiming a discarded tile
	var player_id = action_data.player_id
	var claim_type = action_data.claim_type
	
	# Update local game state
	game_state_data.last_action = {
		"type": "claim",
		"player_id": player_id,
		"claim_type": claim_type
	}

func _handle_form_set(action_data: Dictionary) -> void:
	# Handle a player forming a set (after claiming)
	var player_id = action_data.player_id
	var set_type = action_data.set_type
	var tiles = action_data.tiles
	
	# Update local game state
	game_state_data.last_action = {
		"type": "form_set",
		"player_id": player_id,
		"set_type": set_type,
		"tiles": tiles
	}
	
	# If this is our set, we need to update our hand and exposed sets
	if player_id == network_manager.get_my_id():
		# TODO: Update player's hand and add to exposed sets
		pass

func _handle_sync_game_state(action_data: Dictionary) -> void:
	print("_handle_sync_game_state called with data: " + str(action_data))
	
	# Handle a full game state synchronization (usually sent by host)
	if action_data.has("game_state"):
		var new_state = action_data.game_state
		print("Received new game state: " + str(new_state))
		
		# Update all local game state data
		game_state_data = new_state.duplicate(true)
		
		# Apply state changes to game managers
		
		# Update game state
		if new_state.has("current_state") and game_state_manager != null:
			var state_id = new_state.current_state
			print("Updating game state to: " + str(state_id))
			if game_state_manager.current_state != state_id:
				game_state_manager.change_state(state_id)
		
		# Update round
		if new_state.has("current_round") and game_state_manager != null:
			print("Updating current round to: " + str(new_state.current_round))
			game_state_manager.current_round = new_state.current_round
		
		# Update turn state
		if new_state.has("current_player_index") and new_state.has("current_turn_state") and game_rules != null:
			print("Updating turn state - player: " + str(new_state.current_player_index) + ", turn: " + str(new_state.current_turn_state))
			# TODO: Update game rules turn state
	else:
		print("Warning: Received sync_game_state without game_state data")
	
	sync_completed.emit()
	print("Emitted sync_completed signal")

func _handle_win_hand(action_data: Dictionary) -> void:
	# Handle a player winning the hand
	var player_id = action_data.player_id
	var score = action_data.score
	var winning_tile = action_data.tile if action_data.has("tile") else null
	
	# Update local game state
	game_state_data.last_action = {
		"type": "win",
		"player_id": player_id,
		"score": score,
		"tile": winning_tile
	}
	
	# Transition to scoring state
	if game_state_manager != null:
		var scoring_state = game_state_manager.GameState.SCORING if game_state_manager.has_method("GameState") else 3 # Fallback value
		game_state_manager.change_state(scoring_state)
	else:
		push_warning("Cannot transition to scoring state: GameStateManager not initialized")

# Send a full game state sync to all clients
func send_full_game_state_sync() -> void:
	if network_manager == null:
		push_error("Cannot send game state sync: NetworkManager not initialized")
		return
		
	if not network_manager.is_host():
		push_error("Only host can send full game state sync")
		return
	
	# Prepare game state data
	var sync_data = {
		"game_state": _prepare_full_game_state()
	}
	
	# Send sync data to all clients
	send_game_action(GameAction.SYNC_GAME_STATE, sync_data)

# Prepare a full game state snapshot
func _prepare_full_game_state() -> Dictionary:
	var state = game_state_data.duplicate(true)
	
	# Update with current values from managers
	if game_state_manager != null:
		state.current_state = game_state_manager.current_state
		state.current_round = game_state_manager.current_round
	
	if game_rules:
		state.current_player_index = game_rules._current_player_index
		state.current_turn_state = game_rules._current_turn_state
	
	if tile_manager:
		state.wall_remaining = tile_manager.get_wall_size()
	
	return state

# Signal Handlers

func _on_network_event(event_type, data) -> void:
	# Add detailed logging
	print("StateSync received network event: " + str(event_type) + " with data: " + str(data))
	
	# If event_type is a number, it's a system event from NetworkManager.NetworkEventType enum
	if event_type is int:
		# Handle system events if needed
		match event_type:
			NetworkManager.NetworkEventType.CONNECTED:
				print("Connection event received")
				# Handle new connection if needed
				if network_manager.is_host() and data.has("peer_id"):
					print("New peer connected: " + str(data.peer_id))
				elif data.has("host") and not data.host:
					print("Successfully connected to host")
					
			NetworkManager.NetworkEventType.PLAYER_JOINED:
				print("Player joined: " + str(data.id) if data.has("id") else "unknown")
				# Update our player list if needed
				if data.has("id") and data.has("info"):
					if not game_state_data.players.has(data.id):
						game_state_data.players.append(data.id)
						print("Updated players list: " + str(game_state_data.players))
			
			NetworkManager.NetworkEventType.GAME_STARTED:
				print("Game start event received, waiting for game state sync")
		return
	
	# Otherwise, it should be a game action string
	if GameAction.keys().has(event_type):
		print("Processing game action: " + event_type)
		_process_game_action(event_type, data)
	else:
		print("Ignoring event - not a recognized game action: " + str(event_type))

func _on_game_state_changed(from_state, to_state) -> void:
	# Update local game state
	game_state_data.current_state = to_state
	
	# If we're the host, sync this change to clients
	if network_manager and network_manager.is_host():
		send_game_action(GameAction.SYNC_GAME_STATE, {
			"game_state": {
				"current_state": to_state
			}
		})

func _on_round_started(round_number) -> void:
	# Update local game state
	game_state_data.current_round = round_number
	
	# If we're the host, prepare and send round start data
	if network_manager and network_manager.is_host():
		var round_data = {
			"round": round_number
		}
		
		if tile_manager:
			round_data.wall_remaining = tile_manager.get_wall_size()
		
		send_game_action(GameAction.ROUND_START, round_data)

func _on_round_ended(round_number, scores) -> void:
	# If we're the host, send round end data
	if network_manager and network_manager.is_host() and game_state_manager != null:
		var scoring_state = game_state_manager.GameState.SCORING if game_state_manager.has_method("GameState") else 3 # Fallback value
		send_game_action(GameAction.SYNC_GAME_STATE, {
			"game_state": {
				"current_state": scoring_state,
				"scores": scores
			}
		})

func _on_turn_changed(player_id, turn_state) -> void:
	# Update local game state
	if game_rules:
		game_state_data.current_player_index = game_rules._current_player_index
		game_state_data.current_turn_state = turn_state
	
	# If we're the host, sync this change to clients
	if network_manager and network_manager.is_host():
		send_game_action(GameAction.SYNC_GAME_STATE, {
			"game_state": {
				"current_player_index": game_rules._current_player_index,
				"current_turn_state": turn_state
			}
		})

func _on_game_over(winner_id, score) -> void:
	# If we're the host, send game over data
	if network_manager and network_manager.is_host():
		send_game_action(GameAction.WIN_HAND, {
			"player_id": winner_id,
			"score": score
		}) 