class_name SoundButton
extends TextureButton

const ICON_MUTE_NORMAL: Texture = preload("res://assets/icons/mute_l.png")
const ICON_MUTE_PRESSED: Texture = preload("res://assets/icons/mute_d.png")

const ICON_SOUND_NORMAL: Texture = preload("res://assets/icons/sound_l.png")
const ICON_SOUND_PRESSED: Texture = preload("res://assets/icons/sound_d.png")

onready var _bus_idx := AudioServer.get_bus_index("Master")

func _ready():
	var is_mute := AudioServer.is_bus_mute(self._bus_idx)
	set_normal_texture(ICON_MUTE_NORMAL if is_mute else ICON_SOUND_NORMAL)
	set_pressed_texture(ICON_MUTE_PRESSED if is_mute else ICON_SOUND_PRESSED)

func _on_pressed():
	var is_mute := AudioServer.is_bus_mute(self._bus_idx)
	AudioServer.set_bus_mute(_bus_idx, not is_mute)
	set_normal_texture(ICON_SOUND_NORMAL if is_mute else ICON_MUTE_NORMAL)
	set_pressed_texture(ICON_MUTE_PRESSED if is_mute else ICON_MUTE_PRESSED)
