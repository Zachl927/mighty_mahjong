extends Node

func _ready():
	print("Running project setup validation test")
	
	# Test directory structure
	var dir = DirAccess.open("res://")
	if dir:
		var directories = ["assets", "scenes", "scripts", "resources", "tests"]
		var script_subdirs = ["core", "ui", "networking", "data"]
		
		for directory in directories:
			if not dir.dir_exists(directory):
				print("FAIL: Directory '%s' does not exist" % directory)
			else:
				print("PASS: Directory '%s' exists" % directory)
		
		# Check script subdirectories
		var scripts_dir = DirAccess.open("res://scripts/")
		if scripts_dir:
			for subdir in script_subdirs:
				if not scripts_dir.dir_exists(subdir):
					print("FAIL: Scripts subdirectory '%s' does not exist" % subdir)
				else:
					print("PASS: Scripts subdirectory '%s' exists" % subdir)
		else:
			print("ERROR: Could not open scripts directory")
	else:
		print("ERROR: Could not open project directory")
	
	# Test project configuration
	var config = ConfigFile.new()
	var err = config.load("res://project.godot")
	if err == OK:
		print("PASS: Project configuration file exists and is valid")
		
		# Check specific project settings
		if config.has_section_key("application", "config/name"):
			var project_name = config.get_value("application", "config/name")
			if project_name == "MightyMahjong":
				print("PASS: Project name is correctly set to 'MightyMahjong'")
			else:
				print("FAIL: Project name is '%s', expected 'MightyMahjong'" % project_name)
		
		if config.has_section_key("display", "window/size/viewport_width"):
			var width = config.get_value("display", "window/size/viewport_width")
			if width == 1280:
				print("PASS: Window width is correctly set to 1280")
			else:
				print("FAIL: Window width is %s, expected 1280" % width)
				
		if config.has_section_key("display", "window/size/viewport_height"):
			var height = config.get_value("display", "window/size/viewport_height")
			if height == 720:
				print("PASS: Window height is correctly set to 720")
			else:
				print("FAIL: Window height is %s, expected 720" % height)
	else:
		print("FAIL: Could not load project configuration file")
	
	print("Validation test completed")
