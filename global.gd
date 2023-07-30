extends Node

# world physics
var default_gravity: float = -(ProjectSettings.get_setting("physics/3d/default_gravity") as float)

# race car bodies
const RACE_CAR_BODIES: Array = [
	preload("res://race_cars/body_green.tres"),
	preload("res://race_cars/body_orange.tres"),
	preload("res://race_cars/body_red.tres"),
	preload("res://race_cars/body_white.tres")
]
var default_race_car_body: ArrayMesh = null

# race car physics
var engine_power: float = 5.0
var braking_power: float = -9.0
var max_speed_reverse: float = 5.0
var min_speed_drifting: float = 9.0
var friction_coefficient: float = -2.0
var drag_coefficient: float = -2.0
var traction_coefficient: float = 0.80
var traction_drifting_coefficient: float = 0.1
var max_steering_angle: float = 15.0
var gravity_steering_coefficient: float = 0.25

# circuits
const CIRCUITS: Array = [
	"res://circuits/china_circuit.tscn",
	"res://circuits/poland_circuit.tscn",
	"res://circuits/mexico_circuit.tscn",
	"res://circuits/bahrain_circuit.tscn",
	null,
	null,
	null,
	null
]
var CIRCUITS_CACHE: Array = [
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null
]
