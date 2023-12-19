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


func _ready():
	circuit_control = $CircuitControl
	zoom_camera = $ZoomCamera
	chase_camera = $ChaseCamera
	road_start = $RoadStart
	get_path_direction = funcref(self, "get_path_direction")
	_circuit_ready()


func get_path_direction(_id: int, pos: Vector3, _default: Vector3) -> Vector3:
	var path: Path = $Path
	var path_follow: PathFollow = $Path/PathFollow
	assert(path != null and path_follow != null, "path is null")
	path_follow.offset = path.curve.get_closest_offset(pos)
	return path_follow.transform.basis.z
