class_name MexicoCircuit
extends Circuit

const ROADS_COUNT: int = 28
const ROAD_START_INDEX: int = 0

export(int) var LAPS_COUNT = 4
export(float) var PENALTY = 5.0 # penalty in seconds

func _init():
	road_start_idx = self.ROAD_START_INDEX
	roads_count = self.ROADS_COUNT
	laps_count = self.LAPS_COUNT
	penalty = self.PENALTY



func _ready():
	var pos = [$P1, $P2, $P3, $P4]
	var n: int = len(pos)
	for i in range(n):
		var car = RaceCar.instance()
		car.get_path_direction = funcref(self, "get_path_direction")
		race_cars.append({"car": car, "position": pos[i], "stats": null})
		race_cars_idx[car.get_instance_id()] = i
		if i == 3:
			my_race_car_id = car.get_instance_id()

	circuit_control = $CircuitControl
	zoom_camera = $ZoomCamera
	chase_camera = $ChaseCamera
	road_start = $RoadStart
	_circuit_ready()
	for i in range(n):
		race_cars[i].car.body.set_mesh(Global.RACE_CAR_BODIES[i])



func get_path_direction(_id: int, pos: Vector3, _default: Vector3) -> Vector3:
	var path: Path = $Path
	var path_follow: PathFollow = $Path/PathFollow
	assert(path != null and path_follow != null, "path is null")
	path_follow.offset = path.curve.get_closest_offset(pos)
	return path_follow.transform.basis.z
