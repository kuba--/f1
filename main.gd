class_name Main
extends Control

const ICON_RACE_CAR_GREEN: Texture = preload("res://assets/icons/race_car_green.png")
const ICON_RACE_CAR_ORANGE: Texture = preload("res://assets/icons/race_car_orange.png")
const ICON_RACE_CAR_RED: Texture = preload("res://assets/icons/race_car_red.png")
const ICON_RACE_CAR_WHITE: Texture = preload("res://assets/icons/race_car_white.png")

const ICON_POLAND: Texture = preload("res://assets/icons/poland-96.png")
const ICON_CHINA: Texture = preload("res://assets/icons/china-96.png")
const ICON_MEXICO: Texture = preload("res://assets/icons/mexico-96.png")
const ICON_BAHRAIN: Texture = preload("res://assets/icons/bahrain-96.png")
const ICON_AUSTRALIA: Texture = preload("res://assets/icons/australia-96.png")
const ICON_ITALY: Texture = preload("res://assets/icons/italy-96.png")

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
	$Container/CircuitContainer/BahrainButton,
	$Container/CircuitContainer/AustraliaButton,
	$Container/CircuitContainer/ItalyButton
]
var selected_cicruit_idx = null

onready var root := get_tree()

func _ready():
	Global.race_car_registry.clear()

	$Container/CarContainer/GreenButton.init(ICON_RACE_CAR_GREEN)
	$Container/CarContainer/OrangeButton.init(ICON_RACE_CAR_ORANGE)
	$Container/CarContainer/RedButton.init(ICON_RACE_CAR_RED)
	$Container/CarContainer/WhiteButton.init(ICON_RACE_CAR_WHITE)

	$Container/CircuitContainer/ChinaButton.init(ICON_CHINA)
	$Container/CircuitContainer/PolandButton.init(ICON_POLAND)
	$Container/CircuitContainer/MexicoButton.init(ICON_MEXICO)
	$Container/CircuitContainer/BahrainButton.init(ICON_BAHRAIN)
	$Container/CircuitContainer/AustraliaButton.init(ICON_AUSTRALIA)
	$Container/CircuitContainer/ItalyButton.init(ICON_ITALY)


var _thread: Thread = Thread.new()
func _exit_tree():
	if self._thread.is_active():
		self._thread.wait_to_finish()


func _on_race_car_button_pressed(selected: bool, idx: int):
	if selected:
		if self.selected_race_car_idx != null:
			self.race_car_buttons[self.selected_race_car_idx].reset()
		self.selected_race_car_idx = idx
	elif idx == self.selected_race_car_idx:
		self.selected_race_car_idx = null
	_try_start()


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
	_try_start()


func _set_circuit_buttons_disabled():
	for btn in self.circuit_buttons:
		btn.set_disabled(true)


func _try_start():
	if self.selected_race_car_idx == null or self.selected_cicruit_idx == null:
		return
	Global.default_race_car_body = Global.RACE_CAR_BODIES[selected_race_car_idx]

	var circuit = Global.CIRCUITS[selected_cicruit_idx]
	if circuit == null:
		return

	yield(self.root.create_timer(0.1), "timeout")

	var curcuit_scene: PackedScene = Global.CIRCUITS_CACHE[selected_cicruit_idx] as PackedScene
	if curcuit_scene != null:
		var err := self.root.change_scene_to(curcuit_scene)
		assert(err == OK, "node.change_scene_to error %d" % err)
	else:
		_set_race_car_buttons_disabled()
		_set_circuit_buttons_disabled()
		var err := self._thread.start(self, "_load_circuit")
		assert(err == OK, "thread.start error %d" % err)


func _load_circuit():
	var loader := ResourceLoader.load_interactive(Global.CIRCUITS[self.selected_cicruit_idx], "PackedScene")
	self.circuit_buttons[self.selected_cicruit_idx].set_max(loader.get_stage_count())
	while true:
		var err := loader.poll()
		if err == ERR_FILE_EOF:
			self.circuit_buttons[self.selected_cicruit_idx].set_progress(loader.get_stage_count())
			var curcuit_scene: PackedScene = loader.get_resource() as PackedScene
			Global.CIRCUITS_CACHE[self.selected_cicruit_idx] = curcuit_scene
			self.root.call_deferred("change_scene_to", curcuit_scene)
			return
		assert(err == OK, "loader.poll error %d" % err)
		self.circuit_buttons[self.selected_cicruit_idx].set_progress(loader.get_stage())

