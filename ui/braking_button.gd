class_name BrakingButton
extends TextureButton

var event_action: InputEventAction = InputEventAction.new()

func _init():
	event_action.action = "ui_down"

func _on_button_down():
	event_action.pressed = true
	Input.parse_input_event(event_action)

func _on_button_up():
	event_action.pressed = false
	Input.parse_input_event(event_action)
