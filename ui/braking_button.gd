class_name BrakingButton
extends TextureButton

func _on_button_down():
	Input.action_press("ui_down")

func _on_button_up():
	Input.action_release("ui_down")
