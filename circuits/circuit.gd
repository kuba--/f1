class_name Circuit
extends Spatial

const RaceCar := preload("res://race_cars/race_car.tscn")
const Stats := preload("res://circuits/stats.gd")

var my_race_car_id: int
var race_cars: Array = [
	# idx0: { "stats" => Stats, "car" => RaceCar, "position" => Position3D },
	# idx1: { "stats" => Stats, "car" => RaceCar, "position" => Position3D },
]
var race_cars_idx: Dictionary = {
	# race_car.id => idx
}

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


func _circuit_ready():
	self.circuit_control.init(self.laps_count)
	var err := self.road_start.connect("lights_out", self, "_on_lights_out", [], CONNECT_ONESHOT)
	assert(err == OK, "road_start.connect lights_out error %d" % err)

	match Global.GamePlayMode:
		Global.Mode.TIME:
			var pos = $P1
			var car = RaceCar.instance()
			self.my_race_car_id = car.get_instance_id()
			self.race_cars.append({"car": car, "position": pos, "stats": Stats.new(self.roads_count, self.laps_count, self.penalty)})
			self.race_cars_idx[car.get_instance_id()] = 0
			car.get_path_direction = null
			car.call_deferred("set_physics_process", false)
			car.translate(pos.translation)
			add_child(car)
			car.body.set_mesh(Global.my_race_car_body)

		Global.Mode.RACING:
			var pos = [$P1, $P2, $P3, $P4]
			for i in range(len(pos)):
				var car = RaceCar.instance()
				self.race_cars.append({"car": car, "position": pos[i], "stats": Stats.new(self.roads_count, self.laps_count, self.penalty)})
				self.race_cars_idx[car.get_instance_id()] = i
				car.call_deferred("set_physics_process", false)
				car.translate(pos[i].translation)
				if Global.RACE_CAR_BODIES[i].get_instance_id() == Global.my_race_car_body.get_instance_id():
					self.my_race_car_id = car.get_instance_id()
					car.get_path_direction = null
					# car.set_label("FOO")
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
	_on_zoom_camera_position_set()


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

	if car.get_instance_id() == self.my_race_car_id:
		print_debug(car.get_instance_id(), " ", road_idx, " V=", car._velocity.length())

	var stats: Stats = self.race_cars[self.race_cars_idx[car.get_instance_id()]].stats
	stats.set_time_elapsed(road_idx, time_elapsed)
	if road_idx == self.road_start_idx and car.get_instance_id() == self.my_race_car_id:
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
#	elif road_idx == self.road_start_idx:
#		var l: int = stats.lap_idx() - 1
#		if l < 0:
#			return
#		car.queue_free()

