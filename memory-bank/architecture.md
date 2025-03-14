# Mighty Mahjong Architecture Documentation

This document outlines the architectural structure of the Mighty Mahjong game, documenting the purpose and relationships between key components. It will evolve as the implementation progresses.

## Directory Structure

```
mighty_mahjong/
├── assets/               # Game assets (images, sounds, etc.)
├── scenes/               # Godot scenes
│   ├── main.tscn         # Main entry scene
│   └── test_scene.tscn   # Validation test scene
├── scripts/              # GDScript files
│   ├── core/             # Core game functionality
│   │   └── game_state_manager.gd  # State machine implementation
│   ├── ui/               # User interface scripts
│   │   └── main.gd       # Main scene logic
│   ├── networking/       # Networking components
│   └── data/             # Data persistence
├── resources/            # Resource files
└── tests/                # Test scripts
    └── test_project_setup.gd  # Project structure validation
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
- **Components**: Basic Control node structure with title label
- **Current State**: Minimal implementation for project validation

### Game State Manager
- **File**: `scripts/core/game_state_manager.gd`
- **Purpose**: Manages game states and transitions between them
- **States**: MENU, WAITING, SETUP, PLAYING, SCORING, GAME_OVER
- **Implementation**: Uses enum for state definition, provides state transition methods
- **Design Pattern**: State Machine (follows Windsurf Rule #8)

### Test Framework
- **File**: `tests/test_project_setup.gd` 
- **Purpose**: Validates project structure meets requirements
- **Validation**: Checks directories, project configuration, window size
- **Implementation**: Uses Godot's file system access to verify structure

### UI Components
- **File**: `scripts/ui/main.gd`
- **Purpose**: Handles main scene logic
- **Current State**: Minimal implementation with debug output
- **Future Expansion**: Will be extended to handle menu navigation and scene transitions

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

### Network Manager
- **File**: `scripts/networking/network_manager.gd`
- **Purpose**: Handles network connections using ENet
- **Scene**: `scenes/network_manager.tscn`

### State Synchronization
- **File**: `scripts/networking/state_sync.gd`
- **Purpose**: Ensures game state consistency across clients

### UI Components

### Game UI
- **Scene**: `scenes/game_area.tscn`
- **Purpose**: Contains game board, tiles, and player information

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