class_name Circuit
extends Spatial

const RaceCar := preload("res://race_cars/race_car.tscn")
var race_car: RaceCar = null

const Stats := preload("res://circuits/stats.gd")
var race_car_stats: Dictionary = {}

var time_elapsed: float = 0.0
var started: bool = false

var road_start_index: int = 0
var roads_count: int = 0
var laps_count: int = 0
var penalty: float = 0.0 # penalty in seconds

var race_car_position: Position3D = null
var circuit_control: CircuitControl = null
var zoom_camera: ZoomCamera = null
var chase_camera: ChaseCamera = null
var road_start: RoadStart = null


func _circuit_ready():
	self.circuit_control.init(self.laps_count)
	self.race_car_stats[self.race_car.get_instance_id()] = Stats.new(self.roads_count, self.laps_count, self.penalty)
	var err := self.road_start.connect("lights_out", self, "_on_lights_out", [], CONNECT_ONESHOT)
	assert(err == OK, "road_start.connect lights_out error %d" % err)

	add_child(self.race_car)
	self.race_car.translate(self.race_car_position.translation)
	err = self.race_car.connect("camera_position_changed", self.chase_camera, "_on_camera_position_changed")
	assert(err == OK, "camera_position_changed error %d" % err)

	self.zoom_camera.position = race_car.init_camera_position()
	err = self.zoom_camera.connect("camera_position_set", self, "_on_zoom_camera_position_set", [], CONNECT_ONESHOT)
	assert(err == OK, "camera_position_set error %d" % err)

	self.race_car.call_deferred("set_physics_process", false)


func _process(delta: float):
	self.time_elapsed += delta
	if self.started:
		self.circuit_control.set_time_elapsed(self.time_elapsed)


func _on_lights_out():
	self.time_elapsed = 0.0
	self.started = true
	self.race_car.set_physics_process(true)


func _on_zoom_camera_position_set():
	self.chase_camera.current = true
	self.road_start.lights_timer.start()


func _on_race_car_entered(car: RaceCar, road_idx: int):
	if not self.started:
		return

#	print_debug(car.get_instance_id(), " ", road_idx)

	var stats: Stats = self.race_car_stats[car.get_instance_id()]
	stats.set_time_elapsed(road_idx, time_elapsed)
	if road_idx == self.road_start_index and car.get_instance_id() == self.race_car.get_instance_id():
		var l: int = stats.lap_idx() - 1
		if l < 0:
			return
		var t: Array = stats.lap(l)
		self.circuit_control.set_lap(l, t[1], t[2])
		if l < self.laps_count - 1:
			self.circuit_control.set_lap_idx(stats.lap_idx())
		else:
			self.started = false
			t = stats.total()
			self.circuit_control.set_time_elapsed(t[2])
