class_name Godot4CompatibilityTest
extends Node
##
## Simple test script to verify Godot 4 compatibility
##

func _ready():
	print("=== Godot 4 Compatibility Test ===")
	
	# Test basic Godot 4 features
	test_engine_info()
	test_input_system()
	test_global_access()
	test_physics_settings()
	
	print("=== All tests completed ===")

func test_engine_info():
	print("Engine version: ", Engine.get_version_info())
	print("Project settings config version: ", ProjectSettings.get_setting("", 5))

func test_input_system():
	print("UI actions available:")
	var actions = ["ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next"]
	for action in actions:
		if InputMap.has_action(action):
			print("  ✓ ", action, " - configured")
		else:
			print("  ✗ ", action, " - missing")

func test_global_access():
	if Global:
		print("Global autoload: ✓ Available")
		print("  Engine power: ", Global.engine_power)
		print("  Circuits count: ", Global.CIRCUITS.size())
	else:
		print("Global autoload: ✗ Not available")

func test_physics_settings():
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	print("3D gravity: ", gravity)
	print("Physics engine: ", ProjectSettings.get_setting("physics/3d/physics_engine"))