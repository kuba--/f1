class_name Main
extends Control

onready var race_car_buttons = [
	$Container/CarContainer/GreenButton,
	$Container/CarContainer/OrangeButton,
	$Container/CarContainer/RedButton,
	$Container/CarContainer/WhiteButton
]
var selected_race_car_idx = null

onready var circuit_buttons = [
	$Container/CircuitContainer/ChinaButton,
	$Container/CircuitContainer/PolandButton,
	$Container/CircuitContainer/MexicoButton,
	$Container/CircuitContainer/BahrainButton
]
var selected_cicruit_idx = null

onready var mode_buttons = [
	$Container/ModeContainer/TimeButton,
	$Container/ModeContainer/RacingButton,
	$Container/ModeContainer/MultiplayerButton
]
var selected_mode_idx = null

onready var root := get_tree()
var loaded_curcuit_scene: PackedScene = null

func _ready():
	Global.race_car_registry.clear()
	$SettingsPanel/HBoxContainer/Label.text = Global.my_unique_id.substr(0, 3)

	$Container/CarContainer/GreenButton.init(Global.ICON_RACE_CAR_GREEN)
	$Container/CarContainer/OrangeButton.init(Global.ICON_RACE_CAR_ORANGE)
	$Container/CarContainer/RedButton.init(Global.ICON_RACE_CAR_RED)
	$Container/CarContainer/WhiteButton.init(Global.ICON_RACE_CAR_WHITE)

	$Container/CircuitContainer/ChinaButton.init(Global.ICON_CHINA)
	$Container/CircuitContainer/PolandButton.init(Global.ICON_POLAND)
	$Container/CircuitContainer/MexicoButton.init(Global.ICON_MEXICO)
	$Container/CircuitContainer/BahrainButton.init(Global.ICON_BAHRAIN)

	$Container/ModeContainer/TimeButton.init(Global.ICON_MODE_TIME)
	$Container/ModeContainer/RacingButton.init(Global.ICON_MODE_RACING)
	$Container/ModeContainer/MultiplayerButton.init(Global.ICON_MODE_MULTIPLAYER, true)


func _on_race_car_button_pressed(selected: bool, idx: int):
	if selected:
		if self.selected_race_car_idx != null:
			self.race_car_buttons[self.selected_race_car_idx].reset()
		self.selected_race_car_idx = idx
	elif idx == self.selected_race_car_idx:
		self.selected_race_car_idx = null
	_try_load_circuit()


func _set_race_car_buttons_disabled():
	for btn in self.race_car_buttons:
		btn.set_disabled(true)


func _on_circuit_button_pressed(selected: bool, idx: int):
	if selected:
		if self.selected_cicruit_idx != null:
			self.circuit_buttons[self.selected_cicruit_idx].reset()
		self.selected_cicruit_idx = idx
	elif idx == self.selected_cicruit_idx:
		self.selected_cicruit_idx = null
	_try_load_circuit()


func _set_circuit_buttons_disabled():
	for btn in self.circuit_buttons:
		btn.set_disabled(true)


func _on_mode_button_pressed(selected: bool, idx: int):
	if selected:
		match idx:
			Global.Mode.TIME, Global.Mode.RACING:
				_set_mode_buttons_disabled()
				Global.game_play_mode = idx
#				self.root.call_deferred("change_scene_to", curcuit_scene)
				var err := self.root.change_scene_to(self.loaded_curcuit_scene)
				assert(err == OK, "node.change_scene_to error %d" % err)
			Global.Mode.MULTIPLAYER:
				print_debug("MULTIPLAYER not implemented, yet")

func _set_mode_buttons_disabled():
	for btn in self.mode_buttons:
		btn.set_disabled(true)

func _set_mode_buttons_visible():
	$Container/CarContainer.visible = false
	$Container/CircuitContainer.visible = false
	$Container/ModeContainer.visible = true


func _try_load_circuit():
	if self.selected_race_car_idx == null or self.selected_cicruit_idx == null:
		return
	Global.my_race_car_idx = selected_race_car_idx
	var circuit = Global.CIRCUITS[selected_cicruit_idx]
	if circuit == null:
		return
	self.loaded_curcuit_scene = _load_circuit()
	assert(self.loaded_curcuit_scene != null, "circuit scene is not loaded")
	_set_mode_buttons_visible()


func _load_circuit() -> PackedScene:
	var scene: PackedScene = Global.CIRCUITS_CACHE[selected_cicruit_idx] as PackedScene
	if scene != null:
		return scene
	_set_race_car_buttons_disabled()
	_set_circuit_buttons_disabled()

	var loader := ResourceLoader.load_interactive(Global.CIRCUITS[self.selected_cicruit_idx], "PackedScene")
	self.circuit_buttons[self.selected_cicruit_idx].set_max(loader.get_stage_count())
	while scene == null:
		var err := loader.poll()
		if err == ERR_FILE_EOF:
			self.circuit_buttons[self.selected_cicruit_idx].set_progress(loader.get_stage_count())
			scene = loader.get_resource() as PackedScene
			Global.CIRCUITS_CACHE[self.selected_cicruit_idx] = scene
		assert(err == OK || err == ERR_FILE_EOF, "loader.poll error %d" % err)
		self.circuit_buttons[self.selected_cicruit_idx].set_progress(loader.get_stage())
	return scene
