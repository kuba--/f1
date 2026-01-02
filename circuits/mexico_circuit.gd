class_name MexicoCircuit
extends Circuit

const ROADS_COUNT: int = 28
const ROAD_START_INDEX: int = 0

@export var LAPS_COUNT: int = Global.laps_count as int
@export var PENALTY: float = 5.0 # penalty in seconds

func _init():
	icon = Global.ICON_MEXICO
	road_start_idx = self.ROAD_START_INDEX
	roads_count = self.ROADS_COUNT
	laps_count = self.LAPS_COUNT
	penalty = self.PENALTY


func _ready():
	circuit_control = $CircuitControl
	zoom_camera = $ZoomCamera
	chase_camera = $ChaseCamera
	road_start = $RoadStart
	get_path_direction = Callable(self, "_get_path_direction")
	
	# Disconnect any existing problematic scene connections first
	var roads = [
		$RoadStart, $RoadStraightLong_1, $RoadStraightLong_2, $RoadStraightLong_3,
		$RoadStraightLong_4, $RoadCornerLargeSand_5, $RoadStraight_6, $RoadCornerLargeSand_7,
		$RoadCurved_8, $RoadCurved_9, $RoadCornerLargeBorder_10
	]
	for road in roads:
		if road.body_entered.is_connected(Callable(self, "_on_race_car_entered")):
			road.body_entered.disconnect(Callable(self, "_on_race_car_entered"))
	
	# Connect road segment signals programmatically for Godot 4 compatibility
	$RoadStart.body_entered.connect(_on_road_start_body_entered)
	$RoadStraightLong_1.body_entered.connect(_on_road_straight_long_1_body_entered)
	$RoadStraightLong_2.body_entered.connect(_on_road_straight_long_2_body_entered)
	$RoadStraightLong_3.body_entered.connect(_on_road_straight_long_3_body_entered)
	$RoadStraightLong_4.body_entered.connect(_on_road_straight_long_4_body_entered)
	$RoadCornerLargeSand_5.body_entered.connect(_on_road_corner_large_sand_5_body_entered)
	$RoadStraight_6.body_entered.connect(_on_road_straight_6_body_entered)
	$RoadCornerLargeSand_7.body_entered.connect(_on_road_corner_large_sand_7_body_entered)
	$RoadCurved_8.body_entered.connect(_on_road_curved_8_body_entered)
	$RoadCurved_9.body_entered.connect(_on_road_curved_9_body_entered)
	$RoadCornerLargeBorder_10.body_entered.connect(_on_road_corner_large_border_10_body_entered)
	
	_circuit_ready()

# Override to handle any old scene connections that might still be processed
func _on_race_car_entered(car, road_idx = null):
	# Only process if called with proper road_idx from our wrapper methods
	if road_idx != null and typeof(road_idx) == TYPE_INT:
		super._on_race_car_entered(car, road_idx)


func _get_path_direction(car: RaceCar, pos: Vector3, _default: Vector3) -> Vector3:
	var path: Path3D = $Path3D
	var path_follow: PathFollow3D = $Path3D/PathFollow3D
	assert(path != null and path_follow != null, "path is null")
	var speed: float = car._velocity.length() if car != null else 0.0
	var lookahead: float = clamp(2.5 + speed * 0.35, 2.5, 18.0)
	var closest: float = path.curve.get_closest_offset(pos)
	var length: float = path.curve.get_baked_length()
	var offset: float = closest + lookahead
	if length > 0.0:
		offset = fposmod(offset, length)
	path_follow.progress = offset
	var target_pos: Vector3 = path_follow.global_transform.origin
	var dir := target_pos - pos
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = -path_follow.global_transform.basis.z
		dir.y = 0.0
	return dir.normalized()

# Signal handler wrappers for road segments
func _on_road_start_body_entered(body): _on_race_car_entered(body, 0)
func _on_road_straight_long_1_body_entered(body): _on_race_car_entered(body, 1)
func _on_road_straight_long_2_body_entered(body): _on_race_car_entered(body, 2)
func _on_road_straight_long_3_body_entered(body): _on_race_car_entered(body, 3)
func _on_road_straight_long_4_body_entered(body): _on_race_car_entered(body, 4)
func _on_road_corner_large_sand_5_body_entered(body): _on_race_car_entered(body, 5)
func _on_road_straight_6_body_entered(body): _on_race_car_entered(body, 6)
func _on_road_corner_large_sand_7_body_entered(body): _on_race_car_entered(body, 7)
func _on_road_curved_8_body_entered(body): _on_race_car_entered(body, 8)
func _on_road_curved_9_body_entered(body): _on_race_car_entered(body, 9)
func _on_road_corner_large_border_10_body_entered(body): _on_race_car_entered(body, 10)
