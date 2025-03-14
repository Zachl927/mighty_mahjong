# Implementation Plan: Sichuan Mahjong LAN Game

## Overview
This document provides a step-by-step implementation plan for developing the base version of our Sichuan Mahjong LAN game using the Godot Engine, GDScript, ENet networking, and SQLite. Each step includes specific tasks and validation tests to ensure correct implementation.

## Phase 1: Project Setup and Core Architecture

### Step 1: Project Initialization
1. Create a new Godot project named "MightyMahjong"
2. Set up the project structure with the following directories:
   - `assets/` (for images, sounds, etc.)
   - `scenes/` (for game scenes)
   - `scripts/` (for GDScript files)
   - `resources/` (for resource files)
   - `tests/` (for test scripts)
3. Configure project settings for a 2D game with appropriate window size (1280x720 recommended)

**Validation Test**: Verify that the project opens correctly in Godot with the specified directory structure and can be launched as an empty application.

### Step 2: Create Core Game State Manager
1. Create a new script `scripts/game_state_manager.gd` that implements a state machine
2. Define the following states:
   - `MENU` (main menu)
   - `WAITING` (waiting for players)
   - `SETUP` (setting up game)
   - `PLAYING` (active gameplay)
   - `SCORING` (calculating scores)
   - `GAME_OVER` (end of game)
3. Implement state transition methods with appropriate signals

**Validation Test**: Create a simple scene that displays the current state and allows transitions between states, verifying that the state machine functions correctly.

### Step 3: Design Basic UI Framework
1. Create a main scene `scenes/main.tscn` with a Control node as root
2. Add containers for different UI elements:
   - MainMenu (VBoxContainer)
   - GameArea (Control)
   - PlayerHands (HBoxContainer)
   - DiscardPile (GridContainer)
   - ActionButtons (HBoxContainer)
   - ChatArea (VBoxContainer)
3. Set up basic navigation between UI elements

**Validation Test**: Run the scene and verify that the UI containers are positioned correctly and that navigation works as expected.

## Phase 2: Game Logic Implementation

### Step 4: Create Tile System
1. Create a `scripts/tile.gd` script defining the Tile class with properties:
   - `type` (suit, honor, bonus)
   - `value` (1-9 for suits, specific values for honors/bonus)
   - `image_path` (reference to the corresponding tile image)
2. Create a `scripts/tile_manager.gd` script to:
   - Generate a complete set of 144 Mahjong tiles
   - Shuffle tiles
   - Distribute tiles to players

**Validation Test**: Write a test that creates a full set of Mahjong tiles, verifies that all 144 tiles are present, and checks that the distribution gives each player the correct number of tiles.

### Step 5: Implement Player Hand Management
1. Create a `scripts/player_hand.gd` script that:
   - Stores tiles in a player's hand
   - Allows adding/removing tiles
   - Sorts tiles by type and value
   - Identifies potential sets (Pongs, Kongs, Chows)
2. Create a corresponding scene `scenes/player_hand.tscn` to display the hand

**Validation Test**: Create a test scene that demonstrates adding, removing, and sorting tiles in a player's hand, verifying that all operations work correctly.

### Step 6: Implement Game Rules
1. Create a `scripts/game_rules.gd` script that defines:
   - Turn order
   - Valid actions (draw, discard, claim)
   - Set formation rules (Pong, Kong, Chow)
   - Winning conditions
2. Implement rule checking functions

**Validation Test**: Create test cases for each rule, verifying that legal moves are allowed and illegal moves are prevented.

## Phase 3: Networking Implementation

### Step 7: Set Up Basic Networking
1. Create a `scripts/network_manager.gd` script that:
   - Sets up ENet peer-to-peer connections
   - Implements host and client functionality
   - Handles connection/disconnection events
2. Create a corresponding scene `scenes/network_manager.tscn`

**Validation Test**: Create a test that launches two instances of the game on the same machine, allows one to host and the other to connect, and verifies successful connection.

### Step 8: Implement Game State Synchronization
1. Extend the network manager to synchronize game state:
   - Define network messages for game events (tile draws, discards, claims)
   - Implement sending and receiving of game state updates
   - Handle conflicts and ensure consistency

**Validation Test**: Create a test where two connected clients perform actions (draw, discard), and verify that both clients' game states remain synchronized.

### Step 9: Implement Player Turns and Actions
1. Create a `scripts/turn_manager.gd` script that:
   - Tracks current player turn
   - Manages action sequences (draw → discard)
   - Broadcasts turn changes over the network
2. Implement action buttons in the UI

**Validation Test**: Create a test with multiple connected clients that verifies turn rotation and action sequence enforcement.

## Phase 4: UI and Interaction

### Step 10: Implement Tile Drawing and Discarding
1. Create interaction for drawing tiles:
   - Visual representation of the wall
   - Draw animation
   - Update player hand display
2. Implement discarding mechanism:
   - Selection of tiles in hand
   - Discard animation
   - Update discard pile display

**Validation Test**: Verify that a player can draw a tile, then select and discard a tile, with appropriate visual feedback.

### Step 11: Implement Tile Claiming
1. Create UI for claiming discarded tiles:
   - Popup with options (Pong, Kong, Chow, Mahjong)
   - Validation of claim validity
   - Visual feedback
2. Implement claim processing

**Validation Test**: Create a test scenario where a player discards a tile that another player can claim, and verify that the claim process works correctly.

### Step 12: Implement Basic Scoring
1. Create a `scripts/scoring.gd` script that:
   - Evaluates a winning hand
   - Calculates basic point values
   - Applies scoring rules
2. Create a scoring display UI

**Validation Test**: Create test cases with various winning hands and verify that the scoring system calculates points correctly.

## Phase 5: Data Persistence

### Step 13: Set Up SQLite Database
1. Create a `scripts/database_manager.gd` script that:
   - Initializes SQLite database
   - Creates necessary tables (players, game_sessions, scores)
   - Implements CRUD operations
2. Implement functions for storing and retrieving player data

**Validation Test**: Create a test that stores player data, retrieves it, and verifies it matches the original data.

### Step 14: Implement Currency System
1. Extend the database manager to handle currency:
   - Track player balances
   - Process betting and payouts
   - Update currency display in UI
2. Create a betting UI for game setup

**Validation Test**: Create a test game where players bet currency, complete a game, and verify that the winner's balance increases by the correct amount.

## Phase 6: Integration and Testing

### Step 15: Integrate All Components
1. Connect all previously implemented components:
   - Link game state manager to UI and networking
   - Connect player actions to game rules and networking
   - Integrate scoring with the database
2. Implement seamless transitions between states

**Validation Test**: Play through a complete game cycle from menu to game over, verifying that all components work together correctly.

### Step 16: Implement Comprehensive Error Handling
1. Add error handling for common scenarios:
   - Network disconnections
   - Invalid moves
   - Database errors
2. Implement user-friendly error messages and recovery mechanisms

**Validation Test**: Force various error conditions and verify that the game handles them gracefully without crashing.

### Step 17: Optimize Performance
1. Profile the game to identify bottlenecks
2. Optimize critical paths:
   - Reduce unnecessary processing
   - Batch network messages
   - Optimize database queries
3. Implement performance settings in the UI

**Validation Test**: Compare performance metrics before and after optimization, verifying improved performance.

### Step 18: Final Testing and Debugging
1. Conduct thorough testing of all features
2. Fix any remaining bugs or issues
3. Verify cross-platform compatibility (Windows, macOS, Linux)

**Validation Test**: Complete a full game on each target platform with multiple players, verifying stable and consistent behavior.

## Conclusion

This implementation plan provides a structured approach to developing the base version of the Sichuan Mahjong LAN game. By following these steps and validating each implementation with the provided tests, the development can ensure a solid foundation for the game before adding more advanced features.

Remember to maintain modularity throughout the implementation, as emphasized in the development rules, to avoid a monolithic codebase and ensure maintainability and scalability of the project.

## Implementation Notes

- **Development Approach**: This project will be implemented by a single developer with no strict timeline.
- **Feature Priority**: All features described in this plan are considered "must-have" for the complete implementation.
- **Asset Strategy**: Initial development will use simple placeholder assets that correctly represent the tiles and game elements.
- **Distribution**: The game will be distributed as a Godot project.
- **Progress Tracking**: The progress.md file will be updated to track completed implementation steps.
- **Architecture Documentation**: The architecture.md file will evolve to document the structure and purpose of key components.