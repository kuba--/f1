class_name BoxButton
extends PanelContainer

signal on_pressed(selected)

const BG_COLOR: Color = Color("#525969")

@onready var button: TextureButton = $TextureButton
@onready var progress: TextureProgressBar = $TextureProgressBar

func init(icon: Texture2D, disabled: bool = false):
	button.texture_normal = icon
	button.disabled = disabled
	progress.texture_progress = icon

func reset():
	get_theme_stylebox("panel").bg_color = BG_COLOR

func _on_pressed():
	var stylebox = get_theme_stylebox("panel")
	var selected: bool = stylebox.bg_color == Color.BLACK
	stylebox.bg_color = BG_COLOR if selected else Color.BLACK
	emit_signal("on_pressed", not selected)

func set_disabled(value: bool):
	button.disabled = value

func set_progress(value: float):
	if button.visible:
		button.visible = false
		button.disabled = true
		progress.visible = true
	progress.value = value

func set_min(value: float):
	progress.set_min(value)

func set_max(value: float):
	progress.set_max(value)
