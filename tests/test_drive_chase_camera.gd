extends Node3D

const RaceCar := preload("res://race_cars/race_car.tscn")
var race_car: RaceCar = RaceCar.instantiate()

@onready var chase_camera = $ChaseCamera

func _ready():
	add_child(race_car)
	race_car.connect("camera_position_changed", Callable(chase_camera, "_on_camera_position_changed"))
	race_car.init_camera_position()

