extends Node

const ICON_POLAND: Texture = preload("res://assets/icons/poland-96.png")
const ICON_CHINA: Texture = preload("res://assets/icons/china-96.png")
const ICON_MEXICO: Texture = preload("res://assets/icons/mexico-96.png")
const ICON_BAHRAIN: Texture = preload("res://assets/icons/bahrain-96.png")

const ICON_RACE_CAR_GREEN: Texture = preload("res://assets/icons/race_car_green.png")
const ICON_RACE_CAR_ORANGE: Texture = preload("res://assets/icons/race_car_orange.png")
const ICON_RACE_CAR_RED: Texture = preload("res://assets/icons/race_car_red.png")
const ICON_RACE_CAR_WHITE: Texture = preload("res://assets/icons/race_car_white.png")

const ICON_MODE_TIME: Texture = preload("res://assets/icons/mode_time.png")
const ICON_MODE_RACING: Texture = preload("res://assets/icons/mode_racing.png")
const ICON_MODE_MULTIPLAYER: Texture = preload("res://assets/icons/mode_multiplayer.png")

# world physics
var default_gravity: float = -(ProjectSettings.get_setting("physics/3d/default_gravity") as float)

enum Mode {
	TIME = 0,
	RACING = 1,
	MULTIPLAYER = 2
}
var game_play_mode = null

var race_car_registry: Dictionary = {}
var my_race_car_idx: int = 0
var my_unique_id: String = OS.get_unique_id()

# race car icons
const RACE_CAR_ICONS_SMALL: Array = [
	preload("res://assets/icons/race_car_green_small.png"),
	preload("res://assets/icons/race_car_orange_small.png"),
	preload("res://assets/icons/race_car_red_small.png"),
	preload("res://assets/icons/race_car_white_small.png")
]
func my_race_car_icon() -> Texture:
	return RACE_CAR_ICONS_SMALL[my_race_car_idx]

# race car bodies
const RACE_CAR_BODIES: Array = [
	preload("res://race_cars/body_green.tres"),
	preload("res://race_cars/body_orange.tres"),
	preload("res://race_cars/body_red.tres"),
	preload("res://race_cars/body_white.tres")
]
func my_race_car_body() -> ArrayMesh:
	return RACE_CAR_BODIES[my_race_car_idx]


# race car physics
var engine_power: float = 5.0
var pc_engine_power: float = 4.5
var braking_power: float = -10.0
var max_speed_reverse: float = 5.0
var min_speed_drifting: float = 8.0
var friction_coefficient: float = -2.5
var drag_coefficient: float = -2.5
var traction_coefficient: float = 0.80
var traction_drifting_coefficient: float = 0.1
var max_steering_angle: float = 15.0
var gravity_steering_coefficient: float = 0.25
var laps_count: float = 2.0

# circuits
const CIRCUITS: Array = [
	"res://circuits/china_circuit.tscn",
	"res://circuits/poland_circuit.tscn",
	"res://circuits/mexico_circuit.tscn",
	"res://circuits/bahrain_circuit.tscn"
]
var CIRCUITS_CACHE: Array = [
	null,
	null,
	null,
	null
]
