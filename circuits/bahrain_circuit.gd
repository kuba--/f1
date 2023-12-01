class_name BahrainCircuit
extends Circuit

const ROADS_COUNT: int = 27
const ROAD_START_INDEX: int = 0

export(int) var LAPS_COUNT = 4
export(float) var PENALTY = 5.0 # penalty in seconds

func _init():
	road_start_index = self.ROAD_START_INDEX
	roads_count = self.ROADS_COUNT
	laps_count = self.LAPS_COUNT
	penalty = self.PENALTY
#	print_debug("race_car.id: ", race_car.get_instance_id())
#	race_car2 = RaceCar.instance()
#	race_car2._get_path_direction = funcref(self, "get_path_direction")
#	race_car.engine_power = 5.2



func _ready():
	var pos = [$P1, $P2, $P3, $P4]
	for i in range(4):
		var car = RaceCar.instance()
		car._get_path_direction = funcref(self, "get_path_direction")
		car.engine_power = 5.0
#		car.body.set_mesh(Global.RACE_CAR_BODIES[i])
		race_cars.append({"car": car, "position": pos[i], "stats": null})
		race_cars_idx[car.get_instance_id()] = i
		if race_car_id == 0:
			race_car_id = car.get_instance_id()

#	race_car_position = $P3
#	race_car_position2 = $P2
	circuit_control = $CircuitControl
	zoom_camera = $ZoomCamera
	chase_camera = $ChaseCamera
	road_start = $RoadStart
	._circuit_ready()
	for i in range(4):
		race_cars[i]["car"].body.set_mesh(Global.RACE_CAR_BODIES[i])
#	race_car2.body.set_mesh(Global.RACE_CAR_BODIES[2])



func get_path_direction(id: int, pos: Vector3, default: Vector3) -> Vector3:
	var path: Path = null
	var path_follow: PathFollow = null

	var stats: Stats = race_cars[race_cars_idx[id]].stats
	var idx = stats._road_idx
	if  idx >= 0 and idx < 8:
		path = $Path0_7
		path_follow = $Path0_7/PathFollow
	elif idx >= 8 and idx < 14:
		path = $Path8_13
		path_follow = $Path8_13/PathFollow
	elif idx >= 14 and idx < 27:
		path = $Path14_26
		path_follow = $Path14_26/PathFollow
	else:
		return default

	assert(path != null and path_follow != null, "path is null")
	var offset: float = path.curve.get_closest_offset(pos)

	path_follow.offset = offset
	return path_follow.transform.basis.z
