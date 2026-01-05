class_name CameraButton
extends TextureButton

func _on_pressed():
	Input.action_press("ui_focus_next")
	Input.action_release("ui_focus_next")
