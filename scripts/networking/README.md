# Networking Components

This directory contains the networking components for the Mighty Mahjong game, providing LAN multiplayer support using Godot's built-in networking with ENet.

## Network Manager (`network_manager.gd`)

The Network Manager is the core networking component responsible for:

- Setting up peer-to-peer connections using ENet
- Managing host and client roles
- Handling player connections/disconnections
- Synchronizing player information
- Providing reliable and unreliable transmission channels
- Implementing error handling and automatic reconnection

### Key Features

#### Transmission Channels
Following Windsurf Rule #1, the Network Manager uses:
- **Reliable Channel (0)** - For critical game state updates like score changes, turn management, and game events
- **Unreliable Channel (1)** - For real-time, non-critical data to reduce latency and maintain responsiveness

#### Error Handling
Following Windsurf Rule #4, the Network Manager implements comprehensive error handling:
- Connection failure detection and reporting
- Automatic reconnection attempts with timeout
- Graceful disconnection handling
- Clear error messaging

#### Event System
Following Windsurf Rule #9, the Network Manager uses a robust signal system:
- Network events (connected, disconnected, player joined/left, game started/ended)
- Player info updates
- Connection status changes
- Error notifications

### Architecture

The Network Manager follows a modular design (Windsurf Rule #2) with clear responsibilities:

```
NetworkManager
│
├── Host Functions
│   ├── create_host() - Create a server session
│   ├── start_game() - Start game for all clients
│   └── end_game() - End game for all clients
│
├── Client Functions
│   ├── join_host() - Connect to a host
│   └── disconnect_from_network() - Disconnect from current session
│
├── Player Management
│   ├── update_my_info() - Update local player information
│   ├── register_player() - Register player information with peers
│   └── get_all_players() - Get information about all connected players
│
└── Communication
    ├── send_game_action() - Send game actions to peers
    ├── process_game_action() - Process received game actions
    └── request_player_info() - Request player information
```

### Usage

#### Host Setup
```gdscript
# Create a host on the default port
network_manager.create_host()

# Create a host on a specific port
network_manager.create_host(12345)
```

#### Client Connection
```gdscript
# Connect to a host
network_manager.join_host("192.168.1.100")

# Connect to a host on a specific port
network_manager.join_host("192.168.1.100", 12345)
```

#### Game Actions
```gdscript
# Send a game action to all peers (reliable)
network_manager.send_game_action("draw_tile", {"player_id": 2, "tile_id": 42})

# Send a game action with unreliable transmission
network_manager.send_game_action("player_move", {"position": Vector2(100, 200)}, false)
```

## Testing

The network implementation can be tested using the `test_network_manager.tscn` scene, which:

1. Allows creating a host
2. Allows connecting to a host
3. Displays connected players
4. Shows networking events in a log panel
5. Allows disconnection and reconnection

To test:
1. Launch two instances of the game
2. In the first instance, click "Host Game"
3. In the second instance, ensure the IP address is correct (127.0.0.1 for same machine), then click "Join Game"
4. Observe the player list updating in both instances
5. Test disconnecting from either instance

## Planned Networking Components

### State Synchronization (`state_sync.gd`) - Coming in Step 8
Will be responsible for:
- Synchronizing game state across clients
- Managing conflict resolution
- Ensuring consistency of tile positions, hands, and game progress

### Turn Manager (`turn_manager.gd`) - Coming in Step 9
Will be responsible for:
- Tracking current player turn
- Managing action sequences
- Broadcasting turn changes over the network 