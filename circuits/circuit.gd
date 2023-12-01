class_name Circuit
extends Spatial

const RaceCar := preload("res://race_cars/race_car.tscn")
const Stats := preload("res://circuits/stats.gd")

var race_car_id: int
var race_cars: Array = []
var race_cars_idx: Dictionary = {
	# race_car.id => idx
}
#var race_car: RaceCar = null
#var race_car2: RaceCar = null

#var race_car_position: Position3D = null
#var race_car_position2: Position3D = null
#var race_car_stats: Dictionary = {}

var time_elapsed: float = 0.0
var started: bool = false

var road_start_index: int = 0
var roads_count: int = 0
var laps_count: int = 0
var penalty: float = 0.0 # penalty in seconds

var circuit_control: CircuitControl = null
var zoom_camera: ZoomCamera = null
var chase_camera: ChaseCamera = null
var road_start: RoadStart = null


func _circuit_ready():
	self.circuit_control.init(self.laps_count)
	var err := self.road_start.connect("lights_out", self, "_on_lights_out", [], CONNECT_ONESHOT)
	assert(err == OK, "road_start.connect lights_out error %d" % err)

#	self.race_car_stats[self.race_car.get_instance_id()] = Stats.new(self.roads_count, self.laps_count, self.penalty)
#	self.race_car_stats[self.race_car2.get_instance_id()] = Stats.new(self.roads_count, self.laps_count, self.penalty)
#	add_child(self.race_car)
#	add_child(self.race_car2)
#	self.race_car.translate(self.race_car_position.translation)
#	self.race_car2.translate(race_car_position2.translation)
	for car in self.race_cars:
		car["stats"] = Stats.new(self.roads_count, self.laps_count, self.penalty)
		car["car"].translate(car["position"].translation)
		car["car"].call_deferred("set_physics_process", false)
		add_child(car["car"])

	var race_car = self.race_cars[self.race_cars_idx[self.race_car_id]]["car"]
	err = race_car.connect("camera_position_changed", self.chase_camera, "_on_camera_position_changed")
	assert(err == OK, "camera_position_changed error %d" % err)

	self.zoom_camera.position = race_car.init_camera_position()
	err = self.zoom_camera.connect("camera_position_set", self, "_on_zoom_camera_position_set", [], CONNECT_ONESHOT)
	assert(err == OK, "camera_position_set error %d" % err)

#	self.race_car.call_deferred("set_physics_process", false)
#	self.race_car2.call_deferred("set_physics_process", false)
	_on_zoom_camera_position_set()


func _process(delta: float):
	self.time_elapsed += delta
	if self.started:
		self.circuit_control.set_time_elapsed(self.time_elapsed)


func _on_lights_out():
	self.time_elapsed = 0.0
	self.started = true
	for car in self.race_cars:
		car["car"].set_physics_process(true)
#	self.race_car.set_physics_process(true)
#	self.race_car2.set_physics_process(true)


func _on_zoom_camera_position_set():
	self.chase_camera.current = true
	self.road_start.lights_timer.start()


func _on_race_car_entered(car: RaceCar, road_idx: int):
	if not self.started:
		return

	print_debug(car.get_instance_id(), " ", road_idx, " V=", car._velocity.length())

	var stats: Stats = self.race_cars[self.race_cars_idx[car.get_instance_id()]].stats
	stats.set_time_elapsed(road_idx, time_elapsed)
	if road_idx == self.road_start_index and car.get_instance_id() == self.race_car_id:
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

