class_name ChinaCircuit
extends Circuit

const ROADS_COUNT: int = 18
const ROAD_START_INDEX: int = 0

@export var LAPS_COUNT: int = Global.laps_count as int
@export var PENALTY: float = 5.0 # penalty in seconds

func _init():
	icon = Global.ICON_CHINA
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
		$RoadStart, $RoadCurved1, $RoadCurved2, $RoadCornerLargeSand1, $RoadStraightLong1,
		$RoadStraightLong2, $RoadStraightLong3, $RoadCornerLargeBorder1, $RoadCornerLargeBorder2,
		$RoadCornerLargeBorder3, $RoadStraight1, $RoadCornerLargeBorder4, $RoadCornerLargeBorder5,
		$RoadCornerLargeBorder6, $RoadCurved3, $RoadCurved4, $RoadStraight2, $RoadCornerLargeSand2
	]
	for road in roads:
		if road.body_entered.is_connected(Callable(self, "_on_race_car_entered")):
			road.body_entered.disconnect(Callable(self, "_on_race_car_entered"))
	
	# Connect road segment signals programmatically for Godot 4 compatibility
	$RoadStart.body_entered.connect(_on_road_start_body_entered)
	$RoadCurved1.body_entered.connect(_on_road_curved1_body_entered)
	$RoadCurved2.body_entered.connect(_on_road_curved2_body_entered)
	$RoadCornerLargeSand1.body_entered.connect(_on_road_corner_large_sand1_body_entered)
	$RoadStraightLong1.body_entered.connect(_on_road_straight_long1_body_entered)
	$RoadStraightLong2.body_entered.connect(_on_road_straight_long2_body_entered)
	$RoadStraightLong3.body_entered.connect(_on_road_straight_long3_body_entered)
	$RoadCornerLargeBorder1.body_entered.connect(_on_road_corner_large_border1_body_entered)
	$RoadCornerLargeBorder2.body_entered.connect(_on_road_corner_large_border2_body_entered)
	$RoadCornerLargeBorder3.body_entered.connect(_on_road_corner_large_border3_body_entered)
	$RoadStraight1.body_entered.connect(_on_road_straight1_body_entered)
	$RoadCornerLargeBorder4.body_entered.connect(_on_road_corner_large_border4_body_entered)
	$RoadCornerLargeBorder5.body_entered.connect(_on_road_corner_large_border5_body_entered)
	$RoadCornerLargeBorder6.body_entered.connect(_on_road_corner_large_border6_body_entered)
	$RoadCurved3.body_entered.connect(_on_road_curved3_body_entered)
	$RoadCurved4.body_entered.connect(_on_road_curved4_body_entered)
	$RoadStraight2.body_entered.connect(_on_road_straight2_body_entered)
	$RoadCornerLargeSand2.body_entered.connect(_on_road_corner_large_sand2_body_entered)
	
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
func _on_road_curved1_body_entered(body): _on_race_car_entered(body, 1)
func _on_road_curved2_body_entered(body): _on_race_car_entered(body, 2)
func _on_road_corner_large_sand1_body_entered(body): _on_race_car_entered(body, 3)
func _on_road_straight_long1_body_entered(body): _on_race_car_entered(body, 4)
func _on_road_straight_long2_body_entered(body): _on_race_car_entered(body, 5)
func _on_road_straight_long3_body_entered(body): _on_race_car_entered(body, 6)
func _on_road_corner_large_border1_body_entered(body): _on_race_car_entered(body, 7)
func _on_road_corner_large_border2_body_entered(body): _on_race_car_entered(body, 8)
func _on_road_corner_large_border3_body_entered(body): _on_race_car_entered(body, 9)
func _on_road_straight1_body_entered(body): _on_race_car_entered(body, 10)
func _on_road_corner_large_border4_body_entered(body): _on_race_car_entered(body, 11)
func _on_road_corner_large_border5_body_entered(body): _on_race_car_entered(body, 12)
func _on_road_corner_large_border6_body_entered(body): _on_race_car_entered(body, 13)
func _on_road_curved3_body_entered(body): _on_race_car_entered(body, 14)
func _on_road_curved4_body_entered(body): _on_race_car_entered(body, 15)
func _on_road_straight2_body_entered(body): _on_race_car_entered(body, 16)
func _on_road_corner_large_sand2_body_entered(body): _on_race_car_entered(body, 17)
