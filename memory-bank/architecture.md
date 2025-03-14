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

### Module: Game Rules

The Game Rules module implements the specific rules of Sichuan Mahjong, ensuring proper gameplay mechanics and validation.

#### Components:

1. **GameRules (`scripts/core/game_rules.gd`)**:
   - **Purpose**: Defines and enforces the rules specific to Sichuan Mahjong.
   - **Features**:
     - Action validation for all game moves (draw, discard, claim, win)
     - Suit restriction validation (max 2 suits per hand)
     - Winning pattern validation
     - Constants for game-specific rules (e.g., MAX_SUITS_PER_HAND = 2)
   - **Implementation Details**:
     - Uses modular validation methods for each action type
     - Implements unified `validate_action` method as public API
     - Ensures proper validation of 2-suit restriction by checking tile.suit_type
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

### Networking Components

#### Network Manager
- **File**: `scripts/networking/network_manager.gd`
- **Purpose**: Handles network connections using ENet
- **Scene**: `scenes/network_manager.tscn`

#### State Synchronization
- **File**: `scripts/networking/state_sync.gd`
- **Purpose**: Ensures game state consistency across clients

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