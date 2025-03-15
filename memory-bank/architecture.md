# Mighty Mahjong Architecture Documentation

This document outlines the architectural structure of the Mighty Mahjong game, documenting the purpose and relationships between key components. It will evolve as the implementation progresses.

## Directory Structure

```
mighty_mahjong/
├── assets/               # Game assets (images, sounds, etc.)
│   └── mahjong-tileset/  # Mahjong tile images in various sizes
│       ├── 64/           # 64px tile images
│       │   ├── fulltiles/ # Complete tile images with backgrounds
│       │   ├── labels/    # Label-only versions of tiles
│       │   └── tile.png   # Base tile template
│       ├── 96/           # 96px tile images
│       │   ├── fulltiles/ # Complete tile images with backgrounds
│       │   ├── labels/    # Label-only versions of tiles
│       │   └── tile.png   # Base tile template
│       ├── 128/          # 128px tile images
│       │   ├── fulltiles/ # Complete tile images with backgrounds
│       │   ├── labels/    # Label-only versions of tiles
│       │   └── tile.png   # Base tile template
│       ├── 618/          # 618px tile images
│       │   ├── fulltiles/ # Complete tile images with backgrounds
│       │   ├── labels/    # Label-only versions of tiles
│       │   └── tile.png   # Base tile template
│       ├── license.txt    # CC BY 3.0 license information
│       └── tiles.psd      # Source Photoshop file
├── scenes/               # Godot scenes
│   ├── main.tscn         # Main entry scene
│   ├── test_scene.tscn   # Project validation test scene
│   ├── test_game_state_manager.tscn  # Game state manager validation
│   ├── test_ui_framework.tscn  # UI framework validation
│   └── test_tile_system.tscn  # Tile system validation
├── scripts/              # GDScript files
│   ├── core/             # Core game functionality
│   │   ├── game_state_manager.gd  # State machine implementation
│   │   ├── tile.gd        # Tile class definition
│   │   ├── tile_asset_manager.gd  # Tile asset management
│   │   └── tile_manager.gd  # Tile creation and handling
│   ├── ui/               # User interface scripts
│   │   ├── main.gd       # Main scene logic (initial)
│   │   ├── main_ui_controller.gd  # Main UI controller for navigation and state management
│   │   └── tile_display.gd  # Tile display and interaction
│   ├── networking/       # Networking components
│   └── data/             # Data persistence
├── resources/            # Resource files
└── tests/                # Test scripts
    ├── test_project_setup.gd  # Project structure validation
    ├── test_game_state_manager.gd  # State machine test script
    └── test_tile_system.gd  # Tile system test script
```

## Implemented Components

### Project Configuration
- **File**: `project.godot`
- **Purpose**: Configures the project with appropriate settings
- **Features**: 1280x720 window size, canvas item stretch mode, GL compatibility renderer
- **Details**: Defines the main scene entry point and project name

### Main Scene
- **File**: `scenes/main.tscn`
- **Purpose**: Entry point for the application
- **Components**: 
  - MainMenu (VBoxContainer) - Menu navigation and game setup options
  - GameScreen (Control) - Contains game area and chat components
  - GameArea (Control) - Contains gameplay elements
  - PlayerHands (Control with child containers) - Areas for displaying player tiles
  - DiscardPile (GridContainer) - Area for displaying discarded tiles
  - ActionButtons (HBoxContainer) - Game action controls
  - ChatArea (VBoxContainer) - In-game chat functionality
- **Current State**: Full UI framework implementation with navigation

### Game State Manager
- **File**: `scripts/core/game_state_manager.gd`
- **Purpose**: Manages game states and transitions between them
- **States**: MENU, WAITING, SETUP, PLAYING, SCORING, GAME_OVER
- **Implementation**: 
  - Uses enum for state definition
  - Provides state transition methods with proper enter/exit actions
  - Maintains game data including players, rounds, and session information
  - Emits signals for various game events (player join/leave, game start/end, etc.)
  - Includes helper methods for common game operations
- **Design Pattern**: State Machine (follows Windsurf Rule #8)

### UI Controller
- **File**: `scripts/ui/main_ui_controller.gd`
- **Purpose**: Manages UI navigation and interaction with game state
- **Features**:
  - Connects UI elements to game state manager
  - Handles state-based UI transitions
  - Manages chat functionality
  - Processes user input and game actions
  - Updates UI elements based on game state changes
- **Implementation**: Uses Godot's signals to connect UI elements with game logic (follows Windsurf Rule #9)

### Mahjong Tile Assets
- **Directory**: `assets/mahjong-tileset/`
- **Purpose**: Provides image assets for the tile system implementation
- **Structure**:
  - Multiple resolution options:
    - `64/` - 64x64 pixel tiles (smaller size for mobile or compact UI)
    - `96/` - 96x96 pixel tiles (medium size)
    - `128/` - 128x128 pixel tiles (standard size for desktop)
    - `618/` - 618x618 pixel tiles (high-resolution for detailed view or animations)
  - Within each resolution directory:
    - `fulltiles/` - Complete tile images with backgrounds and decorative elements
    - `labels/` - Label-only versions of tiles (just the symbols without backgrounds)
    - `tile.png` - Base tile template
- **Tile Types**:
  - **Suits**:
    - Bamboo (bamboo1.png through bamboo9.png)
    - Circles (circle1.png through circle9.png)
    - Characters (pinyin1.png through pinyin15.png)
  - **Bonus Tiles**:
    - Seasons (spring.png, summer.png, fall.png, winter.png)
    - Flowers (chrysanthemum.png, lotus.png, orchid.png, peony.png)
- **Asset Format**: PNG files with transparency
- **Total Images**: 41 unique tile designs × 4 resolutions × 2 styles (full/label) = 328 image files
- **License**: Creative Commons Attribution 3.0 (CC BY 3.0) by Code Inferno
- **Usage**: 
  - Will be used by the Tile System for visual representation of Sichuan Mahjong tiles
  - Multiple resolutions allow for responsive design across different screen sizes
  - Label-only versions provide options for custom styling or performance optimization
  - High-resolution (618px) tiles can be used for close-up views or animations

### Tile System
- **Components**:
  - **Tile Class** (`scripts/core/tile.gd`)
    - **Purpose**: Defines properties and behaviors of individual mahjong tiles
    - **Features**:
      - Type enums for categorizing tiles (Suit, Honor, Bonus)
      - Properties for storing tile metadata (type, value, texture)
      - Methods for comparison and identification
      - Support for sorting and matching
    - **Design Pattern**: Resource-based class design
  
  - **Tile Asset Manager** (`scripts/core/tile_asset_manager.gd`)
    - **Purpose**: Manages loading and mapping of tile textures
    - **Features**:
      - Support for multiple resolution tile sets (64px, 96px, 128px, 618px)
      - Systematic mapping of tile types to corresponding images
      - Preloading of textures for efficient access
      - Dynamic changing of tile sizes
    - **Implementation**: Uses Godot's resource loading system
  
  - **Tile Manager** (`scripts/core/tile_manager.gd`)
    - **Purpose**: Manages the creation and handling of the complete set of tiles
    - **Features**:
      - Creates all 144 mahjong tiles according to Sichuan rules
      - Manages the wall (draw pile) with proper shuffling
      - Handles tile drawing and distribution to players
      - Emits signals for game events (wall creation, tile distribution)
    - **Implementation**: Follows Observer pattern using signals (Windsurf Rule #9)
  
  - **Tile Display** (`scripts/ui/tile_display.gd` and `scenes/tile.tscn`)
    - **Purpose**: Provides visual representation and interaction for tiles
    - **Features**:
      - Highlight and selection effects for tiles
      - Signals for tile selection and hover events
      - Visual feedback for player interactions
      - Customizable appearance properties
    - **Implementation**: Extends TextureButton for interactive tile display
  
  - **Tile System Test** (`scenes/test_tile_system.tscn` and `tests/test_tile_system.gd`)
    - **Purpose**: Validates the tile system implementation
    - **Features**:
      - Display of all 144 tiles with correct textures
      - Testing of tile shuffling
      - Distribution of tiles to 2-4 players
      - Dynamic changing of tile resolutions
    - **Implementation**: Provides comprehensive testing of all tile system components

### Module: Player Hand Management

The Player Hand Management system handles all aspects of a player's mahjong tiles, including organization, display, and interaction.

#### Components:

1. **PlayerHand (`scripts/core/player_hand.gd`)**:
   - **Purpose**: Manages the logical representation of a player's hand.
   - **Features**:
     - Stores and manages tiles in the player's hand
     - Provides methods for adding, removing, and sorting tiles
     - Identifies and forms potential sets (Pongs, Kongs, Chows)
     - Tracks exposed sets
     - Checks for winning conditions
     - Emits signals on hand state changes
   - **Dependencies**: Tile, TileManager

2. **PlayerHandDisplay (`scripts/ui/player_hand_display.gd`)**:
   - **Purpose**: Handles the visual representation and user interaction with a player's hand.
   - **Features**:
     - Displays tiles in the player's hand
     - Provides visual feedback for tile selection (single and multi-tile selection)
     - Shows exposed sets
     - Handles user interactions (clicking, dragging)
     - Updates display based on hand changes
     - Provides claim prompts for discarded tiles
   - **Dependencies**: PlayerHand, Tile

3. **Player Hand Scene (`scenes/player_hand.tscn`)**:
   - **Purpose**: Provides the visual layout for the player hand display.
   - **Features**:
     - Contains containers for hand tiles and exposed sets
     - Manages layout and styling of the hand display
   - **Dependencies**: PlayerHandDisplay

#### Test Framework:

1. **Test Player Hand Scene (`scenes/test_player_hand.tscn`)**:
   - **Purpose**: Tests all aspects of the player hand functionality.
   - **Features**:
     - Interface for adding random and specific tiles
     - Testing tile removal (single and multi-tile)
     - Testing set formation
     - Displaying hand information
     - Validating the player hand implementation
   - **Dependencies**: PlayerHand, PlayerHandDisplay, TileManager

2. **Test Player Hand Script (`tests/test_player_hand.gd`)**:
   - **Purpose**: Implements test functionality for the player hand system.
   - **Features**:
     - Manages test actions (add/remove tiles, form sets)
     - Tracks selected tiles (single and multiple)
     - Displays test information and results
     - Tests expected behavior of the player hand system
   - **Dependencies**: PlayerHand, PlayerHandDisplay, TileManager

#### Key Design Features:

1. **Signal-Based Communication**:
   - Components communicate through signals to maintain loose coupling
   - Hand state changes emit signals that update the display

2. **Clean Separation of Logic and Display**:
   - Core logic is contained in PlayerHand while visual elements are in PlayerHandDisplay
   - Clear API boundaries between components

3. **Multi-Tile Selection System**:
   - Tracks selections using array of indices
   - Provides visual feedback for selected tiles
   - Supports batch operations (e.g., removing multiple tiles at once)
   - Signal notifications for selection changes

4. **Test-Driven Development**:
   - Comprehensive test scene to validate functionality
   - Test utilities for various hand configurations

### Module: Network Management

The Network Management system handles multiplayer connectivity, player synchronization, and game state sharing across the network.

#### Components:

1. **NetworkManager (`scripts/networking/network_manager.gd`)**:
   - **Purpose**: Core networking component that manages all multiplayer functionality.
   - **Features**:
     - Establishes and maintains ENet peer-to-peer connections
     - Implements both host and client functionality
     - Manages player connection/disconnection events
     - Synchronizes player information across the network
     - Provides reliable and unreliable transmission channels
     - Implements error handling and reconnection logic
     - Processes remote procedure calls (RPCs) for network communication
     - Emits signals for various network events
   - **Dependencies**: Godot's MultiplayerAPI, ENetMultiplayerPeer

2. **Network Manager Scene (`scripts/networking/network_manager.tscn`)**:
   - **Purpose**: Provides a reusable scene for adding networking to any game component.
   - **Features**:
     - Encapsulated networking node ready for instancing
     - Self-contained functionality that can be attached to game scenes
   - **Dependencies**: NetworkManager script

3. **Test Network Manager Scene (`scenes/test_network_manager.tscn`)**:
   - **Purpose**: Tests and validates the networking functionality.
   - **Features**:
     - UI for hosting and joining games
     - Player name customization
     - Connected player list display
     - Network event logging
     - Connection status monitoring
   - **Dependencies**: NetworkManager, Test Network Manager script

4. **Test Network Manager Script (`tests/test_network_manager.gd`)**:
   - **Purpose**: Implements test functionality for networking system.
   - **Features**:
     - Connects UI elements to network manager functions
     - Processes user interactions (host/join/disconnect)
     - Updates UI based on network events
     - Logs and displays network activities
   - **Dependencies**: NetworkManager

#### Key Design Features:

1. **Client-Server Architecture**:
   - Uses a client-server model with one player acting as host (server)
   - All game actions pass through the host for validation
   - Host manages authoritative game state

2. **Signal-Based Event System**:
   - Network events emit signals that UI and game components can connect to
   - Clear separation between network logic and game components

3. **RPC Communication Patterns**:
   - Uses Godot's built-in RPC system with proper permission annotations
   - Implements both reliable (guaranteed delivery) and unreliable (low latency) channels
   - Optimized data transmission with targeted RPCs (send only to relevant peers)

4. **Player Synchronization**:
   - Tracks all connected players with unique IDs
   - Shares player information (name, status, etc.) across all peers
   - Provides real-time updates when player information changes

5. **Error Handling and Recovery**:
   - Detects disconnections with automatic reconnection attempts
   - Provides clear error messages for connection issues
   - Handles graceful disconnection and cleanup

6. **Network Security Considerations**:
   - Uses proper authority validation for critical game actions
   - Validates game state changes on the host
   - Implements RPC permissions to prevent unauthorized calls

This network architecture supports the multiplayer requirements for Mighty Mahjong while following best practices for Godot 4's networking API and adhering to the project's modularity principles (Windsurf Rule #2).

### Module: Game State Synchronization

The Game State Synchronization system ensures consistent game state across all connected clients in a multiplayer game.

#### Components:

1. **StateSync (`scripts/networking/state_sync.gd`)**:
   - **Purpose**: Manages synchronization of game state data between host and clients.
   - **Features**:
     - Defines game action types with an enum (GAME_START, DRAW_TILE, DISCARD_TILE, etc.)
     - Implements serialization/deserialization of game objects for network transmission
     - Provides methods for sending game actions across the network
     - Processes incoming game actions and updates local state
     - Supports full game state synchronization from host to clients
     - Maintains consistent game state between all players
     - Handles conflict resolution with host authority
     - Emits signals for sync events (sync completed, action received, errors)
   - **Implementation Details**:
     - Uses reliable transmission for critical game state updates (following Rule #1)
     - Implements modular action handler methods (_handle_game_start, _handle_draw_tile, etc.)
     - Maintains a game_state_data dictionary for complete state tracking
     - Integrates with NetworkManager for transmission and GameStateManager for state updates
   - **Dependencies**: NetworkManager, GameStateManager, GameRules, TileManager

2. **State Sync Scene (`scenes/state_sync.tscn`)**:
   - **Purpose**: Provides a reusable scene for adding state synchronization to any game component.
   - **Features**:
     - Self-contained functionality that can be attached to game scenes
     - Properly configured to work with NetworkManager
   - **Dependencies**: StateSync script

3. **Test State Sync Scene (`scenes/test_state_sync.tscn`)**:
   - **Purpose**: Tests and validates the state synchronization functionality.
   - **Features**:
     - UI for hosting and joining games
     - Game control panels for testing actions (draw, discard, claim, win)
     - Game state display showing current synchronized state
     - Action log to track synchronization events
     - Force sync button to test full state synchronization
   - **Dependencies**: StateSync, NetworkManager, GameStateManager

4. **Test State Sync Script (`tests/test_state_sync.gd`)**:
   - **Purpose**: Implements test functionality for the state synchronization system.
   - **Features**:
     - Connects UI elements to state sync functions
     - Provides mock gameplay components for testing (TileManager, GameRules)
     - Updates UI based on game state changes
     - Logs and displays synchronization events
   - **Dependencies**: StateSync, NetworkManager, GameStateManager

#### Key Design Features:

1. **Action-Based Synchronization**:
   - Uses a set of defined game actions for most synchronization
   - Each action has specific data requirements and handling logic
   - Actions are transmitted reliably across the network

2. **Full State Synchronization**:
   - Provides a mechanism for complete state synchronization
   - Host can force a full sync to ensure all clients are consistent
   - Useful for handling reconnections or resolving conflicts

3. **Host Authority Model**:
   - Host maintains authoritative game state
   - Clients send actions to host for validation
   - Host broadcasts validated actions to all clients
   - Prevents cheating and ensures consistent gameplay

4. **Modular Integration**:
   - Clean integration with other game components
   - Follows the modular architecture of the project (Rule #2)
   - Uses signals to notify about synchronization events (Rule #9)

5. **Error Handling**:
   - Detects and reports synchronization errors
   - Provides recovery mechanisms for state inconsistencies
   - Implements robust error handling for network operations (Rule #4)

This state synchronization architecture provides a reliable foundation for multiplayer gameplay in Mighty Mahjong, ensuring that all players see a consistent game state while following best practices for Godot networking.

### Module: Game Rules

The Game Rules module implements the specific rules of Sichuan Mahjong, ensuring proper gameplay mechanics and validation.

#### Components:

1. **GameRules (`scripts/core/game_rules.gd`)**:
   - **Purpose**: Defines and enforces the rules specific to Sichuan Mahjong.
   - **Features**:
     - Action validation for all game moves (draw, discard, peng, gang, win)
     - Turn-based action validation with state tracking (draw phase, discard phase, claim phase)
     - Suit restriction validation (max 2 suits per hand)
     - Winning pattern validation using recursive pattern checking algorithm
     - Seven pairs win condition validation
     - Scoring system with bonuses for special hands
     - Game flow management with proper turn transitions
   - **Implementation Details**:
     - Uses modular validation methods for each action type
     - Implements unified `validate_action` method as public API
     - Ensures proper validation of 2-suit restriction by checking tile.suit_type
     - Maintains game state with player turn tracking and action history
     - Emits signals for game events, turn changes, and game over conditions
   - **Dependencies**: Tile, PlayerHand

2. **Game Rules Tests (`tests/test_game_rules.gd`)**:
   - **Purpose**: Validates the correct implementation of game rules.
   - **Features**:
     - Test cases for all action types
     - Validation of suit restrictions (2-suit rule)
     - Tests for winning patterns
   - **Implementation**: Uses Godot's built-in test framework

### Game State Manager Test
- **Files**: 
  - `scenes/test_game_state_manager.tscn`
  - `tests/test_game_state_manager.gd`
- **Purpose**: Validates the functionality of the Game State Manager
- **Features**:
  - Displays the current game state
  - Provides UI buttons to test transitions between all states
  - Shows state transition logs in the console
- **Implementation**: Uses Godot's Control nodes and signals to demonstrate state machine functionality

### UI Framework Test
- **File**: `scenes/test_ui_framework.tscn`
- **Purpose**: Validates the UI layout and navigation
- **Features**:
  - Tests main menu layout and button functionality
  - Validates game screen layout with player hands, discard area, and action buttons
  - Tests chat functionality
  - Verifies screen transitions based on game state
- **Implementation**: Loads the main scene and adds test instructions panel

### Test Framework
- **File**: `tests/test_project_setup.gd` 
- **Purpose**: Validates project structure meets requirements
- **Validation**: Checks directories, project configuration, window size
- **Implementation**: Uses Godot's file system access to verify structure

## Pending Components

### Player Management
- **File**: `scripts/core/player_hand.gd`
- **Purpose**: Manages player's tiles and legal actions
- **Scene**: `scenes/player_hand.tscn`

## Data Persistence

### Database Manager
- **File**: `scripts/data/database_manager.gd`
- **Purpose**: Handles SQLite operations for player data and game history

### Currency System
- **File**: `scripts/data/currency_manager.gd`
- **Purpose**: Manages in-game currency for betting

## Design Patterns

### State Machine
Used for game state management to organize transitions between different game phases. The implementation follows Windsurf Rule #8 on game state management.

### Observer Pattern (Signals)
The game_state_manager.gd utilizes Godot's signal system to notify about state changes, following Windsurf Rule #9 on using signals and slots for event handling.

### Modular UI Structure
Following Windsurf Rule #6, the UI is built with reusable components, organized in a hierarchical structure for maintainability and flexibility.

### Component-Based Architecture
Following Windsurf Rule #2, the project structure is designed to avoid a monolithic codebase through modularity, with each component having a single responsibility.

## Sichuan Mahjong Specific Considerations

The architecture is designed to support Sichuan Mahjong rules specifically, which will affect:
- Tile set implementation (144 tiles with specific suits, honors, and bonus tiles)
- Game mechanics (draw, discard, claiming patterns specific to Sichuan rules)
- Scoring system (based on Sichuan Mahjong scoring rules)

## Networking Approach

In line with Windsurf Rule #1, the planned networking implementation will:
- Use ENet's reliable transmission for critical game state updates
- Use unreliable transmission for non-critical data
- Implement robust error handling as per Windsurf Rule #4

This architecture follows the Windsurf Rules, particularly emphasizing modularity to avoid a monolithic codebase and leveraging Godot's scene system for organization.