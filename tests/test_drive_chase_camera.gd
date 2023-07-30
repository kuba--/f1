extends Spatial

const RaceCar := preload("res://race_cars/race_car.tscn")
var race_car: RaceCar = RaceCar.instance()

onready var chase_camera = $ChaseCamera

func _ready():
	add_child(race_car)
	race_car.connect("camera_position_changed", chase_camera, "_on_camera_position_changed")
	race_car.init_camera_position()

