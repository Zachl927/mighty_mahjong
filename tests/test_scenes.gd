extends Node

# This script registers test scenes for easy access within the editor

static func get_test_scenes() -> Array:
	return [
		{
			"name": "Project Setup Test",
			"path": "res://scenes/test_scene.tscn",
			"description": "Validates basic project setup and configuration."
		},
		{
			"name": "Game State Manager Test",
			"path": "res://scenes/test_game_state_manager.tscn",
			"description": "Tests the state machine transitions in the game state manager."
		},
		{
			"name": "UI Framework Test",
			"path": "res://scenes/test_ui_framework.tscn",
			"description": "Tests the UI layout, components, and navigation."
		},
		{
			"name": "Tile System Test",
			"path": "res://scenes/test_tile_system.tscn",
			"description": "Tests tile creation, display, and distribution."
		},
		{
			"name": "Player Hand Test",
			"path": "res://scenes/test_player_hand.tscn",
			"description": "Tests player hand management, tile operations, and set formation."
		},
		{
			"name": "Game Rules Test",
			"path": "res://scenes/test_game_rules.tscn",
			"description": "Tests game rules, validation, and scoring."
		},
		{
			"name": "Network Manager Test",
			"path": "res://scenes/test_network_manager.tscn",
			"description": "Tests basic networking functionality, hosting, joining, and player synchronization."
		}
	] 