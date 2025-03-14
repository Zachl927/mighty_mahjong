# Mighty Mahjong

A Sichuan Mahjong game implementation for up to 4 players over LAN. This game follows the traditional Sichuan Mahjong rules with a modern interface.

## Setup Instructions

### Prerequisites
- Godot Engine 4.x (recommended Godot 4.2 or newer)
- No additional dependencies required

### Installation
1. Download and install Godot Engine from [godotengine.org](https://godotengine.org/download)
2. Clone or download this repository
3. Open Godot Engine
4. Click "Import" and select the project.godot file in this directory
5. Click "Import & Edit"

### Project Structure
The project follows a modular architecture to enhance maintainability:
- `assets/` - Images, sounds, and other resources
- `scenes/` - Godot scene files (.tscn)
- `scripts/` - GDScript code, organized into subdirectories:
  - `core/` - Core game functionality
  - `ui/` - User interface scripts
  - `networking/` - Networking components
  - `data/` - Data persistence
- `resources/` - Godot resource files
- `tests/` - Test scripts for validation

## Running Tests
To validate project setup:
1. Open the project in Godot
2. Create a new scene with a Node
3. Attach the test_project_setup.gd script to the Node
4. Run the scene to see validation results

## Game Features
- Sichuan Mahjong rules
- LAN multiplayer support for up to 4 players
- Multiple game modes
- In-game currency system for betting

## Development Status
This project is currently in early development. See `memory-bank/progress.md` for current implementation status.
