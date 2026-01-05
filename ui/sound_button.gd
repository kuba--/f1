class_name SoundButton
extends TextureButton

const ICON_MUTE_NORMAL: Texture2D = preload("res://assets/icons/mute_l.png")
const ICON_MUTE_PRESSED: Texture2D = preload("res://assets/icons/mute_d.png")

const ICON_SOUND_NORMAL: Texture2D = preload("res://assets/icons/sound_l.png")
const ICON_SOUND_PRESSED: Texture2D = preload("res://assets/icons/sound_d.png")

@onready var _bus_idx := AudioServer.get_bus_index("Master")

func _ready():
	var is_mute := AudioServer.is_bus_mute(self._bus_idx)
	texture_normal = ICON_MUTE_NORMAL if is_mute else ICON_SOUND_NORMAL
	texture_pressed = ICON_MUTE_PRESSED if is_mute else ICON_SOUND_PRESSED

func _on_pressed():
	var is_mute := AudioServer.is_bus_mute(self._bus_idx)
	AudioServer.set_bus_mute(_bus_idx, not is_mute)
	texture_normal = ICON_SOUND_NORMAL if is_mute else ICON_MUTE_NORMAL
	texture_pressed = ICON_SOUND_PRESSED if is_mute else ICON_MUTE_PRESSED
