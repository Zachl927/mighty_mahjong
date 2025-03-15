extends Node

# References to nodes in the scene
@onready var network_manager = $NetworkManager
@onready var status_label = $UI/MarginContainer/VBoxContainer/HeaderSection/StatusLabel
@onready var ip_input = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/IPInput
@onready var port_input = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/PortInput
@onready var player_name_input = $UI/MarginContainer/VBoxContainer/NameSection/PlayerNameInput
@onready var host_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/HostButton
@onready var join_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/JoinButton
@onready var disconnect_button = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/HostControls/DisconnectButton
@onready var player_list = $UI/MarginContainer/VBoxContainer/MainContent/LeftSection/Players/PlayerList
@onready var log_text = $UI/MarginContainer/VBoxContainer/MainContent/RightSection/LogPanel/VBoxContainer/LogText

# Called when the node enters the scene tree for the first time
func _ready():
	# Connect signals from network manager
	network_manager.network_event.connect(_on_network_event)
	network_manager.player_info_updated.connect(_on_player_info_updated)
	network_manager.connection_successful.connect(_on_connection_successful)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.host_started.connect(_on_host_started)
	network_manager.disconnected.connect(_on_disconnected)
	network_manager.game_error.connect(_on_game_error)
	
	# Set default values
	port_input.text = str(NetworkManager.DEFAULT_PORT)
	ip_input.text = "127.0.0.1"
	player_name_input.text = "Player " + str(randi() % 1000)
	
	# Connect UI signals
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	disconnect_button.pressed.connect(_on_disconnect_button_pressed)
	player_name_input.text_changed.connect(_on_player_name_changed)
	
	# Update UI
	_update_ui()
	
	# Log
	_log("Test scene initialized")

# Update the UI based on current state
func _update_ui():
	var mode = network_manager.get_network_mode()
	
	# Update connection status
	status_label.text = network_manager.get_connection_status()
	
	# Update button states
	host_button.disabled = mode != NetworkManager.NetworkMode.NONE
	join_button.disabled = mode != NetworkManager.NetworkMode.NONE
	disconnect_button.disabled = mode == NetworkManager.NetworkMode.NONE
	ip_input.editable = mode == NetworkManager.NetworkMode.NONE
	port_input.editable = mode == NetworkManager.NetworkMode.NONE
	
	# Update player list
	_update_player_list()

# Update the player list
func _update_player_list():
	player_list.clear()
	
	var players = network_manager.get_all_players()
	for id in players:
		var player_info = players[id]
		var prefix = ""
		
		# Highlight the local player
		if id == network_manager.get_my_id():
			prefix = "[You] "
		
		# Indicate the host
		if id == 1:
			prefix += "[Host] "
		
		player_list.add_item(prefix + player_info.name + " (ID: " + str(id) + ")")

# Log a message to the log panel
func _log(message):
	var timestamp = Time.get_datetime_string_from_system()
	log_text.text += "[" + timestamp + "] " + message + "\n"
	
	# Autoscroll to bottom
	log_text.scroll_vertical = log_text.get_line_count()

# Signal handlers for network events

func _on_network_event(event_type, data):
	match event_type:
		NetworkManager.NetworkEventType.CONNECTED:
			if data.has("host") and data.host:
				_log("Started hosting")
			else:
				_log("Connected to host")
		NetworkManager.NetworkEventType.DISCONNECTED:
			_log("Disconnected from network")
		NetworkManager.NetworkEventType.PLAYER_JOINED:
			_log("Player joined: " + data.info.name + " (ID: " + str(data.id) + ")")
		NetworkManager.NetworkEventType.PLAYER_LEFT:
			_log("Player left: " + data.info.name + " (ID: " + str(data.id) + ")")
		NetworkManager.NetworkEventType.GAME_STARTED:
			_log("Game started")
		NetworkManager.NetworkEventType.GAME_ENDED:
			_log("Game ended")
		NetworkManager.NetworkEventType.ERROR:
			_log("Error: " + str(data))
		_:
			_log("Event: " + str(event_type) + " - " + str(data))
	
	_update_ui()

func _on_player_info_updated(player_id, info):
	print("Player info updated - ID: ", player_id, " Info: ", info)
	
	# Log the player info update
	var player_name = info.get("name", "Unknown")
	_log("Player " + player_name + " (ID: " + str(player_id) + ") info updated")
	
	# Update the player list in the UI
	_update_player_list()

func _on_connection_successful():
	_log("Successfully connected to host")
	_update_ui()

func _on_connection_failed(error_message):
	_log("Connection failed: " + error_message)
	_update_ui()

func _on_host_started():
	_log("Started hosting on port " + port_input.text)
	_update_ui()

func _on_disconnected(reason):
	_log("Disconnected: " + reason)
	_update_ui()

func _on_game_error(error_message):
	_log("Error: " + error_message)

# UI signal handlers

func _on_host_button_pressed():
	var port = int(port_input.text)
	var result = network_manager.create_host(port)
	
	if result != OK:
		_log("Failed to create host: " + str(result))

func _on_join_button_pressed():
	var address = ip_input.text
	var port = int(port_input.text)
	var result = network_manager.join_host(address, port)
	
	if result != OK:
		_log("Failed to join host: " + str(result))

func _on_disconnect_button_pressed():
	network_manager.disconnect_from_network()
	_log("Disconnected from network")
	_update_ui()

func _on_player_name_changed(new_name):
	print("Player name changed to: " + new_name)
	network_manager.update_my_info({"name": new_name})
	
	# Log locally
	_log("Changed local player name to: " + new_name)
	
	# Force UI update immediately
	_update_player_list() 
