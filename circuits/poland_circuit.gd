class_name PolandCircuit
extends Circuit

const ROADS_COUNT: int = 31
const ROAD_START_INDEX: int = 0

export(int) var LAPS_COUNT = Global.laps_count as int
export(float) var PENALTY = 5.0 # penalty in seconds

func _init():
	icon = Global.ICON_POLAND
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


func get_path_direction(id: int, pos: Vector3, default: Vector3) -> Vector3:
	var path: Path = null
	var path_follow: PathFollow = null

	var stats: Stats = race_cars[race_cars_idx[id]].stats
	var idx = stats.current_road_idx()
	if  idx >= 0 and idx < 8:
		path = $Path0_7
		path_follow = $Path0_7/PathFollow
	elif idx >= 8 and idx < 15:
		path = $Path8_14
		path_follow = $Path8_14/PathFollow
	elif idx >= 15 and idx < 31:
		path = $Path15_30
		path_follow = $Path15_30/PathFollow
	else:
		return default

	assert(path != null and path_follow != null, "path is null")
	path_follow.offset = path.curve.get_closest_offset(pos)
	return path_follow.transform.basis.z
