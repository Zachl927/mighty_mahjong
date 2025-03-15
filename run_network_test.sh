#!/bin/bash

# Path to Godot executable
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
# Path to project
PROJECT_PATH="/Users/zachleslie/src/mighty_mahjong"
# Test scene path
TEST_SCENE="res://scenes/test_state_sync.tscn"

# Run first instance (host)
echo "Starting Host Instance..."
"$GODOT" --path "$PROJECT_PATH" --scene "$TEST_SCENE" &

# Wait a moment to let the first instance start
sleep 2

# Run second instance (client)
echo "Starting Client Instance..."
"$GODOT" --path "$PROJECT_PATH" --scene "$TEST_SCENE" &

echo "Both instances are running. Close them manually when done testing."
echo "Instructions:"
echo "1. In the first instance: Click 'Host Game'"
echo "2. In the second instance: Click 'Join Game'"
echo "3. Once connected, test the game state synchronization"

# Keep the script running until user presses a key
echo "Press any key to terminate both instances..."
read -n 1

# Kill both Godot instances
pkill -f "Godot --path $PROJECT_PATH --scene $TEST_SCENE"
echo "Tests terminated." 