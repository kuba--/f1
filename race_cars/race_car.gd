class_name RaceCar
extends KinematicBody
##
## A race car physics implementation
##

signal camera_position_changed(pos)
onready var camera_positions := $CameraPositions
onready var camera_positions_count: int = camera_positions.get_child_count()

func init_camera_position(idx: int = 0) -> Position3D:
	self._camera_position_idx = wrapi(idx, 0, self.camera_positions_count)
	var pos: Position3D = self.camera_positions.get_child(self._camera_position_idx)
	emit_signal("camera_position_changed", pos)
	return pos

func next_camera_position():
	self._camera_position_idx = wrapi(self._camera_position_idx + 1, 0, self.camera_positions_count)
	emit_signal("camera_position_changed", self.camera_positions.get_child(self._camera_position_idx))

# car engine sound properties
enum {
	ENGINE = 0,
	ACCELERATE,
	BRAKING
}
export(Array, AudioStream) var audio_streams = [
	preload("res://assets/audio/engine.mp3"),
	preload("res://assets/audio/accelerate.mp3"),
	preload("res://assets/audio/braking.mp3")
]
onready var engine_sound: AudioStreamPlayer3D = $EngineSound
func play_engine_sound(stream_idx: int):
	if self.engine_sound.is_playing() and self._audio_stream_idx == stream_idx:
		return
	match stream_idx:
		ENGINE, ACCELERATE, BRAKING:
			if self.engine_sound.is_playing():
				pass
			self._audio_stream_idx = stream_idx
			self.engine_sound.set_stream(self.audio_streams[self._audio_stream_idx])
			self.engine_sound.play()
		_:
			self.engine_sound.stream_paused = true

# car physics properties
export var wheel_base: float = 0.801 ## distance between front/back wheels
var engine_power: float = Global.engine_power
var braking_power: float = Global.braking_power
var max_speed_reverse: float = Global.max_speed_reverse
var min_speed_drifting: float = Global.min_speed_drifting
export var velocity_eps: float = 0.5 # stop if velocity < eps
var friction_coefficient: float = Global.friction_coefficient
var drag_coefficient: float = Global.drag_coefficient
var traction_coefficient: float = Global.traction_coefficient
var traction_drifting_coefficient: float = Global.traction_drifting_coefficient
var max_steering_angle: float = Global.max_steering_angle ## maximum steering angle (in degrees) of front wheels
var gravity_steering_coefficient: float = Global.gravity_steering_coefficient
export var align_interpolate_weight: float = 0.33

onready var max_steering_rad: float = deg2rad(max_steering_angle)

# car parts
onready var body: MeshInstance = $Car/BodyMesh
func set_body(mesh: Mesh):
	self.body.set_mesh(mesh)

onready var wheel_front_left: MeshInstance = $Car/WheelFrontLeftMesh
onready var wheel_front_right: MeshInstance = $Car/WheelFrontRightMesh
onready var front_ray: RayCast = $FrontRay
onready var back_ray: RayCast = $BackRay


# car members
var _acceleration := Vector3.ZERO
var _velocity := Vector3.ZERO
var _steering_angle: float = 0.0
var _is_drifting: bool = false
var _audio_stream_idx: int = ENGINE
var _camera_position_idx: int = 0
var _get_steering_angle: FuncRef = null
var _get_path_direction: FuncRef = null


# context behaviors
const CTX_N_RAYS: int = 32
const CTX_LOOK_DISTANCE: int = 5
const CTX_BRAKE_DISTANCE: int = 10
const CTX_COLLISION_MASK: int = 0b100 # 4 (3rd bit)
onready var ctx_rays := $ContextRays
var _ctx_paths := []
func set_ctx_rays():
	self._ctx_paths.resize(CTX_N_RAYS)
	var angle: float = TAU / CTX_N_RAYS # 2.0 * PI / CTX_N_RAYS
	for i in CTX_N_RAYS:
		var r := RayCast.new()
		r.cast_to = Vector3.FORWARD * CTX_LOOK_DISTANCE
		r.rotation.y = -angle * i
		r.enabled = true
		r.collision_mask |= CTX_COLLISION_MASK
		r.add_exception(self)
		self.ctx_rays.add_child(r)

func set_ctx_paths():
	assert(self._get_path_direction != null, "_get_path_direction is not set")
	# go forward (-transform.basis.z) unless the circuit has a path.
	var dir = self._get_path_direction.call_func(get_instance_id(), transform.origin, -transform.basis.z)
	for i in CTX_N_RAYS:
		var ray: RayCast = self.ctx_rays.get_child(i)
		var d := -ray.global_transform.basis.z
		# set interest
		self._ctx_paths[i] = max(0, d.dot(dir))
		if ray.is_colliding():
			# set danger
			var obj := ray.get_collider()
			self._ctx_paths[i] = self._ctx_paths[i] * 0.725 if Global.race_car_registry.has(obj.get_instance_id()) else 0.0

func _next_direction() -> Vector3:
	var dir := Vector3.ZERO
	for i in CTX_N_RAYS:
		dir += -self.ctx_rays.get_child(i).global_transform.basis.z * self._ctx_paths[i]
	return dir.normalized()


# constructor
func _init():
	Global.race_car_registry[get_instance_id()] = true
	self._get_steering_angle = funcref(self, "_get_gravity_steering_angle") \
		if OS.has_touchscreen_ui_hint()  \
		else funcref(self, "_get_action_steering_angle")
	return self

# called when the node enters the scene tree for the first time.
func _ready():
	set_body(Global.my_race_car_body)
	if self._get_path_direction != null:
		set_ctx_rays()
	play_engine_sound(ENGINE)

func _get_action_steering_angle() -> float:
	var strength: float = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	return strength * self.max_steering_rad

func _get_gravity_steering_angle() -> float:
	var gravity: Vector3 = Input.get_gravity()
	var strength: float = atan2(-gravity.x, -gravity.y) * gravity_steering_coefficient
	if abs(strength) > self.max_steering_rad:
		strength = self.max_steering_rad * sign(strength)
	return strength

func _get_ctx_steering_angle() -> float:
	set_ctx_paths()
	var dir := _next_direction()
	# find angle - how far dir vector is to the left (negative)
	# or right (positive) of forward (-self.transform.basis.z) vector.
	var v = -self.transform.basis.z.cross(dir)
	var a = v.dot(self.transform.basis.y)
	var steer_angle = a * self.max_steering_rad * 2.0
	self._acceleration = -self.transform.basis.z * self.engine_power
	# check forward ray
	var ray = self.ctx_rays.get_child(0)
	if ray.is_colliding():
		var obj = ray.get_collider()
		var d = transform.origin.distance_to(obj.transform.origin)
		if (d < 0.25 * CTX_BRAKE_DISTANCE) or (not Global.race_car_registry.has(obj.get_instance_id()) and d < CTX_BRAKE_DISTANCE):
			self._acceleration = -self.transform.basis.z * self.braking_power
	return steer_angle

func _input(event: InputEvent):
	if event.is_action_pressed("ui_select"):
		print_debug(global_translation)
	if event.is_action_pressed("ui_focus_next"):
		next_camera_position()
	if event.is_action_pressed("ui_up"):
		play_engine_sound(ACCELERATE)
	if Input.is_action_just_released("ui_up") or event.is_action_pressed("ui_down"):
		play_engine_sound(BRAKING)

func _input_process():
	if self._get_path_direction != null:
		self._steering_angle = _get_ctx_steering_angle()
		return

	self._steering_angle = self._get_steering_angle.call_func()
	if Input.is_action_pressed("ui_up"):
		self._acceleration = -self.transform.basis.z * self.engine_power
	if Input.is_action_pressed("ui_down"):
		self._acceleration = -self.transform.basis.z * self.braking_power


func _physics_process(delta: float):
	if is_on_floor():
		self._acceleration = Vector3.ZERO
		_input_process()
		_friction_process(delta)
		_steering_process(delta)
	self._acceleration.y = Global.default_gravity
	self._velocity = move_and_slide_with_snap(self._velocity + self._acceleration * delta, \
	-self.transform.basis.y, Vector3.UP, true)
	_align_to_slope()


func _friction_process(delta: float):
	var a: float = self._acceleration.length()
	var v: float = self._velocity.length()
	if a < delta and v < self.velocity_eps:
		play_engine_sound(ENGINE)
		# stop the car
		self._velocity.x = 0.0
		self._velocity.z = 0.0

	var friction: Vector3 = self._velocity * self.friction_coefficient * delta
	var drag: Vector3 = self._velocity * v * self.drag_coefficient * delta
	self._acceleration += friction + drag


func _steering_process(delta: float):
	var v: float = self._velocity.length()
	var dv: float = v *  delta

	# drifting occurs when the car's velocity is _high_ or the car is already drifting and turning
	self._is_drifting = (v > self.min_speed_drifting) or (self._is_drifting and self._steering_angle != 0.0)
	var traction = self.traction_drifting_coefficient if self._is_drifting else self.traction_coefficient

	# turn wheels
	var wheel_angle: float = self._steering_angle * 2.0
	self.wheel_front_left.rotation.y = wheel_angle
	self.wheel_front_right.rotation.y = wheel_angle

	var wheel_base05: float = self.wheel_base * 0.5
	var wheel_front: Vector3 = (self.transform.origin - self.transform.basis.z * wheel_base05) \
	+ (self._velocity.rotated(self.transform.basis.y, self._steering_angle) * delta)
	var wheel_back: Vector3 = (self.transform.origin + self.transform.basis.z * wheel_base05) \
	+ (self._velocity * delta)

	var heading: Vector3 = wheel_back.direction_to(wheel_front)
	var cos_slip_angle: float = heading.dot(self._velocity.normalized())
	if cos_slip_angle > 0.0:
		# rotate wheels fwd.
		self.wheel_front_left.rotation.x += dv
		self.wheel_front_right.rotation.x += dv
		self._velocity = lerp(self._velocity, heading * v, traction)
	if cos_slip_angle < 0.0:
		# rotate wheels rev.
		self.wheel_front_left.rotation.x -= dv
		self.wheel_front_right.rotation.x -= dv
		# no drifting on reverse
		self._velocity = -heading * min(v, self.max_speed_reverse)

	look_at(self.transform.origin + heading, self.transform.basis.y)


func _align_to_slope():
	var is_front_colliding := self.front_ray.is_colliding()
	var front_ray_normal := self.front_ray.get_collision_normal() if is_front_colliding else Vector3.UP

	var is_back_colliding = self.back_ray.is_colliding()
	var back_ray_normal := self.back_ray.get_collision_normal() if is_back_colliding else Vector3.UP

	if is_front_colliding or is_back_colliding:
		var normal: Vector3 = (front_ray_normal + back_ray_normal) / 2.0
		self.global_transform.basis.x = -self.global_transform.basis.z.cross(normal)
		self.global_transform.basis.y = normal
		self.global_transform.basis = self.global_transform.basis.orthonormalized()
		self.global_transform = self.global_transform.interpolate_with(self.global_transform, self.align_interpolate_weight)
