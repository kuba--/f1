class_name Circuit
extends Spatial

const RaceCar := preload("res://race_cars/race_car.tscn")
const Stats := preload("res://circuits/stats.gd")
const StatsPopup: PackedScene = preload("res://ui/stats_popup.tscn")

var icon: Texture = null

var my_race_car_id: int
var race_cars: Array = [
	# idx0: { "icon" => Texture, "stats" => Stats, "car" => RaceCar, "position" => Position3D },
	# idx1: { "icon" => Texture, "stats" => Stats, "car" => RaceCar, "position" => Position3D },
]
var race_cars_idx: Dictionary = {
	# race_car.id => idx
}

class ResultsSorter:
	# [
	# 	{ "icon" => Texture, "label" => String, "total" => [ float, float, float ], "disqualified" => bool }
	# ]
	static func by_total(r1, r2) -> bool:
		if r1.disqualified:
			return false
		if r2.disqualified:
			return true
		return r1.total[2] < r2.total[2]

var time_elapsed: float = 0.0
var started: bool = false

var road_start_idx: int = 0
var roads_count: int = 0
var laps_count: int = 0
var penalty: float = 0.0 # penalty in seconds

var circuit_control: CircuitControl = null
var zoom_camera: ZoomCamera = null
var chase_camera: ChaseCamera = null
var road_start: RoadStart = null

var get_path_direction: FuncRef = null

var stats_popup: StatsPopup = null

func _circuit_ready():
	self.circuit_control.init(self.laps_count)
	var err := self.road_start.connect("lights_out", self, "_on_lights_out", [], CONNECT_ONESHOT)
	assert(err == OK, "road_start.connect lights_out error %d" % err)
	match Global.game_play_mode:
		Global.Mode.TIME:
			var pos = $P1
			var car = RaceCar.instance()
			self.my_race_car_id = car.get_instance_id()
			self.race_cars.append({
				"icon": Global.my_race_car_icon(),
				"car": car,
				"position": pos,
				"stats": Stats.new(self.roads_count, self.laps_count, self.penalty)
			})
			self.race_cars_idx[car.get_instance_id()] = 0
			car.get_path_direction = null
			car.call_deferred("set_physics_process", false)
			car.translate(pos.translation)
			add_child(car)
			car.body.set_mesh(Global.my_race_car_body())

		Global.Mode.RACING:
			var pos = [$P1, $P2, $P3, $P4]
			for i in range(len(pos)):
				var car = RaceCar.instance()
				self.race_cars.append({
					"icon": Global.RACE_CAR_ICONS_SMALL[i],
					"car": car,
					"position": pos[i],
					"stats": Stats.new(self.roads_count, self.laps_count, self.penalty)
				})
				self.race_cars_idx[car.get_instance_id()] = i
				car.call_deferred("set_physics_process", false)
				car.translate(pos[i].translation)
				if i == Global.my_race_car_idx:
					self.my_race_car_id = car.get_instance_id()
					car.get_path_direction = null
					# car.set_label(":-)")
				else:
					car.get_path_direction = self.get_path_direction
					car.set_label("PC" + str(i+1))
				add_child(car)
				car.body.set_mesh(Global.RACE_CAR_BODIES[i])
		_:
			print_debug("game play mode '", Global.GamePlayMode, "' not implemented, yet")
			return

	var my_race_car = self.race_cars[self.race_cars_idx[self.my_race_car_id]].car
	err = my_race_car.connect("camera_position_changed", self.chase_camera, "_on_camera_position_changed")
	assert(err == OK, "camera_position_changed error %d" % err)

	self.zoom_camera.position = my_race_car.init_camera_position()
	err = self.zoom_camera.connect("camera_position_set", self, "_on_zoom_camera_position_set", [], CONNECT_ONESHOT)
	assert(err == OK, "camera_position_set error %d" % err)
	# uncomment following line to skip zoom camera intro
#	_on_zoom_camera_position_set()


func _process(delta: float):
	self.time_elapsed += delta
	if self.started:
		self.circuit_control.set_time_elapsed(self.time_elapsed)


func _on_lights_out():
	self.time_elapsed = 0.0
	self.started = true
	for rc in self.race_cars:
		rc.car.set_physics_process(true)


func _on_zoom_camera_position_set():
	self.chase_camera.current = true
	self.road_start.lights_timer.start()


func _on_race_car_entered(car: RaceCar, road_idx: int):
	if not self.started:
		return
	# if car.get_instance_id() == self.my_race_car_id:
	# 	print_debug(car.get_instance_id(), " ", road_idx, " V=", car._velocity.length())

	var stats: Stats = self.race_cars[self.race_cars_idx[car.get_instance_id()]].stats
	if stats.finished():
		return
	stats.set_time_elapsed(road_idx, time_elapsed)

	if road_idx != self.road_start_idx:
		return
	# else full lap

	if stats.lap_idx() == 0:
		# just started
		return

	if car.get_instance_id() == self.my_race_car_id:
		var li: int = stats.lap_idx() - 1
		var lt: Array = stats.lap(li)
		self.circuit_control.set_lap(li, lt[1], lt[2])
		if stats.lap_idx() == self.laps_count:
			#
			# finish the race
			#
			self.circuit_control.set_time_elapsed(stats.total()[2])
			var err := get_tree().create_timer(1.0).connect("timeout", self, "_on_finish_race")
			assert(err == OK, "create_timer error %d" % err)
		else:
			self.circuit_control.set_lap_idx(stats.lap_idx())



func _on_finish_race():
	self.started = false
	self.chase_camera.call_deferred("set_physics_process", false)
	self.zoom_camera.call_deferred("set_physics_process", false)

	# [
	# 	{ "icon" => Texture, "label" => String, "total" => float }
	# ]
	var results: Array = []
	for rc in self.race_cars:
		var total: Array = rc.stats.total() if rc.stats.finished() else rc.stats.approx_total()
		results.append({
			"icon": rc.icon,
			"label": rc.car.get_label(),
			"total": total,
			"disqualified": (total[2] == 0.0) or (rc.stats._laps_count - rc.stats._lap_idx > 1)
		})
		rc.car.call_deferred("set_physics_process", false)
		self.call_deferred("remove_child", rc.car)
	results.sort_custom(ResultsSorter, "by_total")

	self.stats_popup = StatsPopup.instance()
	self.stats_popup.init(self.icon, results)
	add_child(self.stats_popup)
	self.circuit_control.visible = false
	self.stats_popup.popup_centered()
