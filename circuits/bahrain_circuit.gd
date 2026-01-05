class_name BahrainCircuit
extends Circuit

const ROADS_COUNT: int = 27
const ROAD_START_INDEX: int = 0

@export var LAPS_COUNT: int = Global.laps_count as int
@export var PENALTY: float = 5.0 # penalty in seconds

func _init():
	icon = Global.ICON_BAHRAIN
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
		$RoadStart,
		$RoadStraightLong1,
		$RoadStraightLong2,
		$RoadCornerLargeBorder3,
		$RoadCornerLargeBorder4,
		$RoadCurved5,
		$RoadCurved6,
		$RoadCurved7,
		$RoadCornerLargeBorder8,
		$RoadRampLongWall9,
		$RoadStraightLong10,
		$RoadStraightBridge11,
		$RoadStraightLong12,
		$RoadRampLongWall13,
		$RoadCornerLargeBorder14,
		$RoadCornerLargeBorder15,
		$RoadStraightLong16,
		$RoadCornerLargeBorder17,
		$RoadCurved18,
		$RoadCornerLargeBorder19,
		$RoadStraight20,
		$RoadCornerLargeBorder21,
		$RoadStraightLong22,
		$RoadCornerLargeBorder23,
		$RoadStraight24,
		$RoadCornerLargeBorder25,
		$RoadStraight26,
	]
	for road in roads:
		if road.body_entered.is_connected(Callable(self, "_on_race_car_entered")):
			road.body_entered.disconnect(Callable(self, "_on_race_car_entered"))
	
	# Connect road segment signals programmatically for Godot 4 compatibility
	$RoadStart.body_entered.connect(_on_road_start_body_entered)
	$RoadStraightLong1.body_entered.connect(_on_road_straight_long1_body_entered)
	$RoadStraightLong2.body_entered.connect(_on_road_straight_long2_body_entered)
	$RoadCornerLargeBorder3.body_entered.connect(_on_road_corner_large_border3_body_entered)
	$RoadCornerLargeBorder4.body_entered.connect(_on_road_corner_large_border4_body_entered)
	$RoadCurved5.body_entered.connect(_on_road_curved5_body_entered)
	$RoadCurved6.body_entered.connect(_on_road_curved6_body_entered)
	$RoadCurved7.body_entered.connect(_on_road_curved7_body_entered)
	$RoadCornerLargeBorder8.body_entered.connect(_on_road_corner_large_border8_body_entered)
	$RoadRampLongWall9.body_entered.connect(_on_road_ramp_long_wall9_body_entered)
	$RoadStraightLong10.body_entered.connect(_on_road_straight_long10_body_entered)
	$RoadStraightBridge11.body_entered.connect(_on_road_straight_bridge11_body_entered)
	$RoadStraightLong12.body_entered.connect(_on_road_straight_long12_body_entered)
	$RoadRampLongWall13.body_entered.connect(_on_road_ramp_long_wall13_body_entered)
	$RoadCornerLargeBorder14.body_entered.connect(_on_road_corner_large_border14_body_entered)
	$RoadCornerLargeBorder15.body_entered.connect(_on_road_corner_large_border15_body_entered)
	$RoadStraightLong16.body_entered.connect(_on_road_straight_long16_body_entered)
	$RoadCornerLargeBorder17.body_entered.connect(_on_road_corner_large_border17_body_entered)
	$RoadCurved18.body_entered.connect(_on_road_curved18_body_entered)
	$RoadCornerLargeBorder19.body_entered.connect(_on_road_corner_large_border19_body_entered)
	$RoadStraight20.body_entered.connect(_on_road_straight20_body_entered)
	$RoadCornerLargeBorder21.body_entered.connect(_on_road_corner_large_border21_body_entered)
	$RoadStraightLong22.body_entered.connect(_on_road_straight_long22_body_entered)
	$RoadCornerLargeBorder23.body_entered.connect(_on_road_corner_large_border23_body_entered)
	$RoadStraight24.body_entered.connect(_on_road_straight24_body_entered)
	$RoadCornerLargeBorder25.body_entered.connect(_on_road_corner_large_border25_body_entered)
	$RoadStraight26.body_entered.connect(_on_road_straight26_body_entered)
	
	_circuit_ready()

# Override to handle any old scene connections that might still be processed
func _on_race_car_entered(car, road_idx = null):
	# Only process if called with proper road_idx from our wrapper methods
	if road_idx != null and typeof(road_idx) == TYPE_INT:
		super._on_race_car_entered(car, road_idx)


func _get_path_direction(car: RaceCar, pos: Vector3, default: Vector3) -> Vector3:
	var path: Path3D = null
	var path_follow: PathFollow3D = null

	var stats: Stats = race_cars[race_cars_idx[car]].stats
	var idx = stats.current_road_idx()
	if  idx >= 0 and idx < 8:
		path = $Path0_7
		path_follow = $Path0_7/PathFollow3D
	elif idx >= 8 and idx < 14:
		path = $Path8_13
		path_follow = $Path8_13/PathFollow3D
	elif idx >= 14 and idx < 27:
		path = $Path14_26
		path_follow = $Path14_26/PathFollow3D
	else:
		return default

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
func _on_road_straight_long1_body_entered(body): _on_race_car_entered(body, 1)
func _on_road_straight_long2_body_entered(body): _on_race_car_entered(body, 2)
func _on_road_corner_large_border3_body_entered(body): _on_race_car_entered(body, 3)
func _on_road_corner_large_border4_body_entered(body): _on_race_car_entered(body, 4)
func _on_road_curved5_body_entered(body): _on_race_car_entered(body, 5)
func _on_road_curved6_body_entered(body): _on_race_car_entered(body, 6)
func _on_road_curved7_body_entered(body): _on_race_car_entered(body, 7)
func _on_road_corner_large_border8_body_entered(body): _on_race_car_entered(body, 8)
func _on_road_ramp_long_wall9_body_entered(body): _on_race_car_entered(body, 9)
func _on_road_straight_long10_body_entered(body): _on_race_car_entered(body, 10)
func _on_road_straight_bridge11_body_entered(body): _on_race_car_entered(body, 11)
func _on_road_straight_long12_body_entered(body): _on_race_car_entered(body, 12)
func _on_road_ramp_long_wall13_body_entered(body): _on_race_car_entered(body, 13)
func _on_road_corner_large_border14_body_entered(body): _on_race_car_entered(body, 14)
func _on_road_corner_large_border15_body_entered(body): _on_race_car_entered(body, 15)
func _on_road_straight_long16_body_entered(body): _on_race_car_entered(body, 16)
func _on_road_corner_large_border17_body_entered(body): _on_race_car_entered(body, 17)
func _on_road_curved18_body_entered(body): _on_race_car_entered(body, 18)
func _on_road_corner_large_border19_body_entered(body): _on_race_car_entered(body, 19)
func _on_road_straight20_body_entered(body): _on_race_car_entered(body, 20)
func _on_road_corner_large_border21_body_entered(body): _on_race_car_entered(body, 21)
func _on_road_straight_long22_body_entered(body): _on_race_car_entered(body, 22)
func _on_road_corner_large_border23_body_entered(body): _on_race_car_entered(body, 23)
func _on_road_straight24_body_entered(body): _on_race_car_entered(body, 24)
func _on_road_corner_large_border25_body_entered(body): _on_race_car_entered(body, 25)
func _on_road_straight26_body_entered(body): _on_race_car_entered(body, 26)
