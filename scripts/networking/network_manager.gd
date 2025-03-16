extends Node
class_name NetworkManager

# Networking constants
const DEFAULT_PORT = 28960
const MAX_PLAYERS = 4
const RECONNECT_TIMEOUT = 3 # seconds
const ENCRYPTION_KEY = "mighty_mahjong_secure_key"

# ENet configuration
const RELIABLE_ORDERED = 0 # Channel for critical game state updates
const UNRELIABLE = 1 # Channel for non-critical updates

# Enums for clarity
enum NetworkMode {NONE, CLIENT, HOST}
enum NetworkEventType {
	CONNECTED,
	DISCONNECTED,
	PLAYER_JOINED,
	PLAYER_LEFT,
	GAME_STARTED,
	GAME_ENDED,
	ERROR
}

# Properties
var _network_mode: int = NetworkMode.NONE
var _peer: ENetMultiplayerPeer = null
var _host_address: String = ""
var _host_port: int = DEFAULT_PORT
var _player_info: Dictionary = {}  # Contains player data like {id: {name, ready, etc}}
var _my_info: Dictionary = {}  # Local player info
var _connection_attempts: int = 0
var _max_connection_attempts: int = 3
var _reconnecting: bool = false
var _test_mode: bool = false  # For testing without actual network connections

# Signals
signal network_event(event_type, data)
signal player_info_updated(player_id, info)
signal connection_successful()
signal connection_failed(error_message)
signal host_started()
signal disconnected(reason)
signal game_error(error_message)

# Initialize with default player info
func _init() -> void:
	_my_info = {
		"name": "Player",
		"ready": false
	}

# Called when the node enters the scene tree
func _ready() -> void:
	# Set up multiplayer API signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Set test mode for testing without actual network connections
func set_test_mode(enabled: bool) -> void:
	_test_mode = enabled
	print("Network manager test mode: ", _test_mode)

# Check if we're in test mode
func is_test_mode() -> bool:
	return _test_mode

# Create a server (host) session
func create_host(port: int = DEFAULT_PORT) -> Error:
	if _network_mode != NetworkMode.NONE:
		return ERR_ALREADY_IN_USE
	
	if _test_mode:
		# In test mode, we simulate hosting without actual network
		_network_mode = NetworkMode.HOST
		_player_info[1] = _my_info.duplicate()  # Host is always ID 1
		
		emit_signal("host_started")
		emit_signal("network_event", NetworkEventType.CONNECTED, {"host": true})
		emit_signal("player_info_updated", 1, _player_info[1])
		
		return OK
	
	_peer = ENetMultiplayerPeer.new()
	var error = _peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		emit_signal("game_error", "Failed to create server: " + str(error))
		return error
	
	# Configure the channels for different types of data
	# Note: compress_with_range_coder is not available in this Godot version
	
	# Set as multiplayer peer
	multiplayer.set_multiplayer_peer(_peer)
	
	# Update mode and add host to player list
	_network_mode = NetworkMode.HOST
	_player_info[1] = _my_info.duplicate()  # Host is always ID 1
	
	emit_signal("host_started")
	emit_signal("network_event", NetworkEventType.CONNECTED, {"host": true})
	emit_signal("player_info_updated", 1, _player_info[1])
	
	return OK

# Join an existing host
func join_host(address: String, port: int = DEFAULT_PORT) -> Error:
	if _network_mode != NetworkMode.NONE:
		return ERR_ALREADY_IN_USE
	
	if _test_mode:
		# In test mode, we simulate joining without actual network
		_network_mode = NetworkMode.CLIENT
		_host_address = address
		_host_port = port
		
		# Simulate connection success
		emit_signal("connection_successful")
		emit_signal("network_event", NetworkEventType.CONNECTED, {"host": false})
		
		# Add ourselves as player 2 for testing
		_player_info[2] = _my_info.duplicate()
		emit_signal("player_info_updated", 2, _player_info[2])
		
		return OK
	
	_host_address = address
	_host_port = port
	_connection_attempts = 0
	
	return _attempt_connection()

# Helper function to attempt connection
func _attempt_connection() -> Error:
	_peer = ENetMultiplayerPeer.new()
	
	# Configure ENet peer properties
	var error = _peer.create_client(_host_address, _host_port)
	
	if error != OK:
		emit_signal("connection_failed", "Failed to create client: " + str(error))
		return error
	
	# Configure the channels for different types of data
	# Note: compress_with_range_coder is not available in this Godot version
	
	# Set as multiplayer peer
	multiplayer.set_multiplayer_peer(_peer)
	
	# Update mode
	_network_mode = NetworkMode.CLIENT
	
	return OK

# Disconnect from the current network session
func disconnect_from_network() -> void:
	if _peer:
		_peer.close()
	
	_network_mode = NetworkMode.NONE
	_player_info.clear()
	emit_signal("disconnected", "Disconnected from network")
	emit_signal("network_event", NetworkEventType.DISCONNECTED, {})

# Send player info to all peers
@rpc("any_peer", "reliable")
func register_player(info: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	print("Received player info from peer ID: ", sender_id, " with info: ", info)
	
	# Store the player info in local dictionary
	_player_info[sender_id] = info.duplicate()
	
	# Debug the current player list
	print("Current player list: ", _player_info)
	
	# Notify about the updated player info with explicit signals
	emit_signal("player_info_updated", sender_id, info)
	emit_signal("network_event", NetworkEventType.PLAYER_JOINED, {"id": sender_id, "info": info})
	
	# If we're the host, distribute this info to all other peers
	if _network_mode == NetworkMode.HOST:
		print("Host distributing player info from ", sender_id, " to all peers")
		
		# Use direct peer list instead of stored player list for iteration
		for peer_id in multiplayer.get_peers():
			if peer_id != sender_id:  # Skip the sender
				print("Distributing to peer: ", peer_id)
				register_player.rpc_id(peer_id, info)
				
		# Also update host UI
		if sender_id != 1:  # Not the host's own info
			print("Host UI updated with player ID: ", sender_id)
			# Force an additional signal emit to ensure UI updates
			call_deferred("emit_signal", "player_info_updated", sender_id, info)

# Update local player info and broadcast to other players
func update_my_info(info: Dictionary) -> void:
	# Log the update request
	print("Updating my info with: ", info)
	
	# Store previous info for comparison
	var old_info = _my_info.duplicate()
	
	# Update local info - DIRECTLY SET VALUES (avoid using merge)
	for key in info:
		_my_info[key] = info[key]
	
	print("Updated local info: ", _my_info)
	
	# Get our own ID
	var my_id = multiplayer.get_unique_id()
	
	# Always update our local player list
	_player_info[my_id] = _my_info.duplicate()
	
	# Broadcast if connected
	if _network_mode != NetworkMode.NONE:
		print("Broadcasting updated info to others, my ID: ", my_id)
		
		if _network_mode == NetworkMode.CLIENT:
			# Client sends to host
			print("Client sending updated info to host")
			register_player.rpc_id(1, _my_info)
		else:
			# Host broadcasts to all
			print("Host broadcasting updated info to all peers")
			# Use multiplayer.get_peers() instead of _peer.get_peers()
			for peer_id in multiplayer.get_peers():
				print("Sending updated info to peer: ", peer_id)
				register_player.rpc_id(peer_id, _my_info)
	
	# Always emit the signal locally to update our own UI, even if we're not connected
	# This ensures our local UI always shows our current name
	print("Emitting local signal for UI update with info: ", _my_info)
	emit_signal("player_info_updated", my_id, _my_info)
	
	# Log what changed
	var changes = []
	for key in _my_info:
		if !old_info.has(key) or old_info[key] != _my_info[key]:
			changes.append(key + ": " + str(old_info.get(key, "none")) + " -> " + str(_my_info[key]))
	if changes.size() > 0:
		print("Changed fields: ", ", ".join(changes))
	else:
		print("No fields changed")

# Start the game for all connected players
func start_game() -> void:
	if _network_mode != NetworkMode.HOST:
		emit_signal("game_error", "Only the host can start the game")
		return
	
	print("NetworkManager: Starting game")
	
	# Send RPC to all clients to start the game
	if not _test_mode:
		start_game_rpc.rpc()
	else:
		# In test mode, directly call the RPC method for all simulated clients
		print("Test mode: Directly triggering game start for all clients")
		# First emit for host
		emit_signal("network_event", NetworkEventType.GAME_STARTED, {})
		
		# Then simulate RPCs to clients
		# Get all client IDs (excluding host) from player info
		for client_id in _player_info.keys():
			if client_id != 1:  # Skip host (ID 1)
				print("Simulating game start for client ID: " + str(client_id))
				# We can't directly call start_game_rpc() as it checks for client mode
				# Instead, directly emit the event for the test framework
				call_deferred("_simulate_client_game_start", client_id)

# Helper function to simulate game start event for clients in test mode
func _simulate_client_game_start(client_id: int) -> void:
	# The test framework should detect this event 
	# and propagate it to the appropriate client instance
	print("NetworkManager: Simulating game start for client ID: " + str(client_id))
	emit_signal("network_event", NetworkEventType.GAME_STARTED, {"target_client": client_id})

# Remote procedure to start the game on all clients
@rpc("authority", "reliable")
func start_game_rpc() -> void:
	# This will be executed on all clients (and host) when received
	if _network_mode == NetworkMode.CLIENT:
		emit_signal("network_event", NetworkEventType.GAME_STARTED, {})

# End the game and notify all players
func end_game() -> void:
	if _network_mode != NetworkMode.HOST:
		emit_signal("game_error", "Only the host can end the game")
		return
	
	# Send RPC to all clients to end the game
	end_game_rpc.rpc()
	
	# Emit local signal
	emit_signal("network_event", NetworkEventType.GAME_ENDED, {})

# Remote procedure to end the game on all clients
@rpc("authority", "reliable")
func end_game_rpc() -> void:
	# This will be executed on all clients (and host) when received
	if _network_mode == NetworkMode.CLIENT:
		emit_signal("network_event", NetworkEventType.GAME_ENDED, {})

# Get all player information
func get_all_players() -> Dictionary:
	return _player_info.duplicate()

# Get the local player's network ID
func get_my_id() -> int:
	if _test_mode:
		# In test mode, return 1 if host, 2 if client
		return 1 if is_host() else 2
	
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 0

# Get the current network mode
func get_network_mode() -> int:
	return _network_mode

# Check if we are the host
func is_host() -> bool:
	return _network_mode == NetworkMode.HOST

# Get the current host address and port
func get_host_address() -> Dictionary:
	return {
		"address": _host_address,
		"port": _host_port
	}

# Event handlers for multiplayer API signals

# Called when a new peer connects to the host
func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	
	# Log connection event for debugging
	emit_signal("network_event", NetworkEventType.CONNECTED, {"peer_id": id})
	
	# When we are the host, send all existing players to the new peer
	if _network_mode == NetworkMode.HOST:
		print("Host sending existing player info to new peer: ", id)
		# Send existing players to the new peer
		for peer_id in _player_info:
			# Skip sending info about the new player to itself
			if peer_id != id:
				print("Sending player ", peer_id, " info to peer ", id)
				register_player.rpc_id(id, _player_info[peer_id])
		
		# We also need the new peer to send their info to us
		print("Requesting info from peer: ", id)
		request_player_info.rpc_id(id)

# Called when a peer disconnects
func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	
	if _player_info.has(id):
		var player_data = _player_info[id]
		_player_info.erase(id)
		emit_signal("network_event", NetworkEventType.PLAYER_LEFT, {"id": id, "info": player_data})

# Called when successfully connected to the server (client side)
func _on_connected_to_server() -> void:
	print("Connected to server!")
	_connection_attempts = 0
	_reconnecting = false
	
	# Get our unique ID
	var my_id = multiplayer.get_unique_id()
	print("My client ID: ", my_id)
	
	# Update local player list with our info
	_player_info[my_id] = _my_info.duplicate()
	
	# Register with the server - IMPORTANT: Send directly to the host (ID 1)
	print("Registering with server as: ", _my_info)
	register_player.rpc_id(1, _my_info)
	
	# Emit signals AFTER updating local data
	emit_signal("connection_successful")
	emit_signal("network_event", NetworkEventType.CONNECTED, {"host": false})
	emit_signal("player_info_updated", my_id, _my_info)

# Called when connection to the server fails (client side)
func _on_connection_failed() -> void:
	print("Connection failed!")
	_connection_attempts += 1
	
	if _connection_attempts < _max_connection_attempts and not _reconnecting:
		# Try to reconnect
		_reconnecting = true
		print("Attempting to reconnect in ", RECONNECT_TIMEOUT, " seconds...")
		await get_tree().create_timer(RECONNECT_TIMEOUT).timeout
		_reconnecting = false
		var error = _attempt_connection()
		if error != OK:
			emit_signal("connection_failed", "Failed to reconnect: " + str(error))
	else:
		emit_signal("connection_failed", "Failed to connect after multiple attempts")
		_network_mode = NetworkMode.NONE

# Called when disconnected from the server (client side)
func _on_server_disconnected() -> void:
	print("Server disconnected!")
	_player_info.clear()
	
	emit_signal("disconnected", "The server has disconnected")
	emit_signal("network_event", NetworkEventType.DISCONNECTED, {})
	
	_network_mode = NetworkMode.NONE

# Request player info from a client
@rpc("any_peer", "reliable")
func request_player_info() -> void:
	print("Received request for player info")
	# Client should respond with their info
	if _network_mode == NetworkMode.CLIENT:
		var my_id = multiplayer.get_unique_id()
		print("Sending player info to host, my ID: ", my_id)
		register_player.rpc_id(1, _my_info)  # Send to host only

# For debugging purposes
func get_connection_status() -> String:
	var status = "Mode: "
	
	match _network_mode:
		NetworkMode.NONE:
			status += "None"
		NetworkMode.CLIENT:
			status += "Client (connected to " + _host_address + ":" + str(_host_port) + ")"
		NetworkMode.HOST:
			status += "Host (listening on port " + str(_host_port) + ")"
	
	status += ", Players: " + str(_player_info.size())
	return status

# Send a game action to all players or a specific player
func send_game_action(action_type: String, action_data: Dictionary, reliable: bool = true, target_id: int = 0) -> void:
	if _test_mode:
		# In test mode, we simulate sending by directly emitting the signal
		# This allows testing without actual network
		call_deferred("_simulate_receive_game_action", action_type, action_data)
		return
	
	if _network_mode == NetworkMode.NONE:
		push_error("Cannot send game action: Not connected to network")
		return
	
	# Choose the appropriate RPC channel based on reliability needs
	var channel = RELIABLE_ORDERED if reliable else UNRELIABLE
	
	# Prepare the data to send
	var data = {
		"action": action_type,
		"data": action_data,
		"sender_id": get_my_id(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Send using RPC
	if target_id > 0:
		# Send to specific player
		rpc_id(target_id, "_receive_game_action", data, channel)
	else:
		# Send to all players
		rpc("_receive_game_action", data, channel)

# Simulate receiving a game action in test mode
func _simulate_receive_game_action(action_type: String, action_data: Dictionary) -> void:
	# Create a simulated data packet
	var data = {
		"action": action_type,
		"data": action_data,
		"sender_id": get_my_id(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("NetworkManager simulating receive of action: " + action_type)
	
	# Process it as if received from network
	_process_game_action(data)

# Process a received game action
func _process_game_action(data: Dictionary) -> void:
	# Extract data from the packet
	var action_type = data.get("action", "")
	var action_data = data.get("data", {})
	var sender_id = data.get("sender_id", 0)
	
	print("NetworkManager processing game action: " + action_type + " from sender: " + str(sender_id))
	
	# Emit signal for listeners using the action type as the event type
	# This allows StateSync to receive and process the game action
	emit_signal("network_event", action_type, action_data)
	
	print("NetworkManager emitted network_event with action: " + action_type)

# Receive a game action from the network
@rpc("any_peer", "unreliable_ordered")
func _receive_game_action(data: Dictionary, channel: int) -> void:
	print("Received game action via RPC: " + str(data))
	
	# Process the received action
	_process_game_action(data)
