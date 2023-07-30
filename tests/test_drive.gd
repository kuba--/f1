class_name TestDrive
extends Spatial

const RaceCar := preload("res://race_cars/race_car.tscn")
var race_car: RaceCar = RaceCar.instance()


func _input(event: InputEvent):
	if event.is_action_pressed("ui_focus_next"):
		print_debug(race_car.global_translation)

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(race_car)


func _on_body_entered(body, idx):
	prints(body.get_instance_id(), idx)
