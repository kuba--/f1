class_name ChinaCircuit
extends Circuit

const ROADS_COUNT: int = 18
const ROAD_START_INDEX: int = 0

export(int) var LAPS_COUNT = 4
export(float) var PENALTY = 5.0 # penalty in seconds

func _init():
	road_start_idx = self.ROAD_START_INDEX
	roads_count = self.ROADS_COUNT
	laps_count = self.LAPS_COUNT
	penalty = self.PENALTY
	race_car = RaceCar.instance()
#	print_debug("race_car.id: ", self.race_car.get_instance_id())


func _ready():
	race_car_position = $P4
	circuit_control = $CircuitControl
	zoom_camera = $ZoomCamera
	chase_camera = $ChaseCamera
	road_start = $RoadStart
	._circuit_ready()
