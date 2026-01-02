class_name AccelerateButton
extends TextureButton

func _on_button_down():
	Input.action_press("ui_up")

func _on_button_up():
	Input.action_release("ui_up")
