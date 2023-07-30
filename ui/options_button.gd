class_name OptionsButton
extends TextureButton

func _on_pressed():
	$OptionsPopup.visible = not $OptionsPopup.visible
