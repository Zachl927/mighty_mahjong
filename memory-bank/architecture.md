# Mighty Mahjong Architecture Documentation

This document outlines the architectural structure of the Mighty Mahjong game, documenting the purpose and relationships between key components. It will evolve as the implementation progresses.

## Directory Structure

```
mighty_mahjong/
├── assets/               # Game assets (images, sounds, etc.)
├── scenes/               # Godot scenes
│   ├── main.tscn         # Main entry scene
│   ├── test_scene.tscn   # Project validation test scene
│   ├── test_game_state_manager.tscn  # Game state manager validation
│   └── test_ui_framework.tscn  # UI framework validation
├── scripts/              # GDScript files
│   ├── core/             # Core game functionality
│   │   └── game_state_manager.gd  # State machine implementation
│   ├── ui/               # User interface scripts
│   │   ├── main.gd       # Main scene logic (initial)
│   │   └── main_ui_controller.gd  # Main UI controller for navigation and state management
│   ├── networking/       # Networking components
│   └── data/             # Data persistence
├── resources/            # Resource files
└── tests/                # Test scripts
    ├── test_project_setup.gd  # Project structure validation
    └── test_game_state_manager.gd  # State machine test script
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

### Tile System
- **File**: `scripts/core/tile.gd`
- **Purpose**: Defines tile properties and behavior
- **Related Files**: `scripts/core/tile_manager.gd` (handles tile generation and distribution)

### Player Management
- **File**: `scripts/core/player_hand.gd`
- **Purpose**: Manages player's tiles and legal actions
- **Scene**: `scenes/player_hand.tscn`

### Game Rules
- **File**: `scripts/core/game_rules.gd`
- **Purpose**: Implements Sichuan Mahjong rules and validates player actions

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