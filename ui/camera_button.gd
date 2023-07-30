class_name CameraButton
extends TextureButton

var event_action: InputEventAction = InputEventAction.new()

func _init():
	event_action.action = "ui_focus_next"
	event_action.pressed = true

func _on_pressed():
	Input.parse_input_event(event_action)
