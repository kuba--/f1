class_name RaceCar
extends CharacterBody3D
##
## A race car physics implementation
##

signal camera_position_changed(pos)
@onready var camera_positions := $CameraPositions
@onready var camera_positions_count: int = camera_positions.get_child_count()

func init_camera_position(idx: int = 0) -> Marker3D:
	self._camera_position_idx = wrapi(idx, 0, self.camera_positions_count)
	var pos: Marker3D = self.camera_positions.get_child(self._camera_position_idx)
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
@export var audio_streams = [ # (Array, AudioStream)
	preload("res://assets/audio/engine.mp3"),
	preload("res://assets/audio/accelerate.mp3"),
	preload("res://assets/audio/braking.mp3")
]
@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
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
			self.engine_sound.stop()

# car physics properties
@export var wheel_base: float = 0.801 ## distance between front/back wheels
var engine_power: float = Global.engine_power
var pc_engine_power: float = Global.pc_engine_power
var braking_power: float = Global.braking_power
var max_speed_reverse: float = Global.max_speed_reverse
var min_speed_drifting: float = Global.min_speed_drifting
@export var velocity_eps: float = 0.5 # stop if velocity < eps
var friction_coefficient: float = Global.friction_coefficient
var drag_coefficient: float = Global.drag_coefficient
var traction_coefficient: float = Global.traction_coefficient
var traction_drifting_coefficient: float = Global.traction_drifting_coefficient
var max_steering_angle: float = Global.max_steering_angle ## maximum steering angle (in degrees) of front wheels
var gravity_steering_coefficient: float = Global.gravity_steering_coefficient
@export var align_interpolate_weight: float = 0.33

@onready var max_steering_rad: float = deg_to_rad(max_steering_angle)

# car parts
@onready var body: MeshInstance3D = $Car/BodyMesh
func set_body(mesh: Mesh):
	self.body.set_mesh(mesh)

@onready var wheel_front_left: MeshInstance3D = $Car/WheelFrontLeftMesh
@onready var wheel_front_right: MeshInstance3D = $Car/WheelFrontRightMesh
@onready var front_ray: RayCast3D = $FrontRay
@onready var back_ray: RayCast3D = $BackRay


# car members
var _acceleration := Vector3.ZERO
var _velocity := Vector3.ZERO
var _steering_angle: float = 0.0
var _is_drifting: bool = false
var _audio_stream_idx: int = ENGINE
var _camera_position_idx: int = 0

var get_steering_angle: Callable = Callable()
var get_path_direction: Callable = Callable()


# AI driving system
const AI_FRONT_RAY_DISTANCE: float = 15.0
const AI_SIDE_RAY_DISTANCE: float = 8.0
const AI_BRAKE_DISTANCE: float = 5.0
const AI_COLLISION_MASK: int = 0b100  # 4 (3rd bit)

const AI_LOOK_STEER_GAIN: float = 1.6
const AI_SPEED_FAST: float = 30.0
const AI_SPEED_TURN: float = 12.0
const AI_MIN_THROTTLE_SCALE: float = 0.25

@onready var ctx_rays := $ContextRays
var _ai_front_ray: RayCast3D
var _ai_left_ray: RayCast3D
var _ai_right_ray: RayCast3D
var _ai_far_left_ray: RayCast3D
var _ai_far_right_ray: RayCast3D

func set_ctx_rays():
	# Create 5 rays: front, left, right, far-left, far-right
	_ai_front_ray = _create_ai_ray(0.0, AI_FRONT_RAY_DISTANCE)
	_ai_left_ray = _create_ai_ray(deg_to_rad(25), AI_SIDE_RAY_DISTANCE)
	_ai_right_ray = _create_ai_ray(deg_to_rad(-25), AI_SIDE_RAY_DISTANCE)
	_ai_far_left_ray = _create_ai_ray(deg_to_rad(50), AI_SIDE_RAY_DISTANCE * 0.7)
	_ai_far_right_ray = _create_ai_ray(deg_to_rad(-50), AI_SIDE_RAY_DISTANCE * 0.7)

func _create_ai_ray(angle_y: float, distance: float) -> RayCast3D:
	var r := RayCast3D.new()
	r.target_position = Vector3.FORWARD * distance
	r.rotation.y = angle_y
	r.enabled = true
	r.collision_mask = AI_COLLISION_MASK
	r.add_exception(self)
	self.ctx_rays.add_child(r)
	return r

func _get_ctx_steering_angle() -> float:
	if self.get_path_direction.is_null():
		return 0.0
	
	# Get desired direction from circuit path
	var path_dir: Vector3 = self.get_path_direction.call(self, global_transform.origin, -global_transform.basis.z)
	path_dir.y = 0.0
	if path_dir.length_squared() < 0.0001:
		path_dir = -global_transform.basis.z
		path_dir.y = 0.0
	path_dir = path_dir.normalized()

	# Calculate base steering to follow path (signed angle on XZ plane)
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var angle: float = forward.signed_angle_to(path_dir, Vector3.UP)
	var path_steer: float = clamp(angle * AI_LOOK_STEER_GAIN, -self.max_steering_rad, self.max_steering_rad)

	# Corner speed control (slow down when large steering is needed)
	var steer_ratio: float = clamp(abs(path_steer) / max(self.max_steering_rad, 0.0001), 0.0, 1.0)
	var desired_speed: float = lerp(AI_SPEED_FAST, AI_SPEED_TURN, steer_ratio)
	var current_speed: float = self._velocity.length()
	var throttle_scale: float = clamp(1.0 - steer_ratio, AI_MIN_THROTTLE_SCALE, 1.0)
	var wants_brake_for_turn := current_speed > desired_speed + 1.0
	# Default acceleration (may be overridden by obstacle/brake logic below)
	self._acceleration = -self.transform.basis.z * self.pc_engine_power * throttle_scale
	
	# Check for obstacles and adjust steering/throttle
	var avoid_steer: float = 0.0
	var should_brake := false
	var should_slow := false
	
	# Front ray - brake if obstacle ahead
	if _ai_front_ray and _ai_front_ray.is_colliding():
		var dist: float = global_transform.origin.distance_to(_ai_front_ray.get_collision_point())
		if dist < AI_BRAKE_DISTANCE:
			should_brake = true
		elif dist < AI_BRAKE_DISTANCE * 2.0:
			should_slow = true
	
	# Side rays - steer away from obstacles
	var left_blocked := false
	var right_blocked := false
	var left_dist: float = AI_SIDE_RAY_DISTANCE
	var right_dist: float = AI_SIDE_RAY_DISTANCE
	
	if _ai_left_ray and _ai_left_ray.is_colliding():
		left_blocked = true
		left_dist = global_transform.origin.distance_to(_ai_left_ray.get_collision_point())
	if _ai_right_ray and _ai_right_ray.is_colliding():
		right_blocked = true
		right_dist = global_transform.origin.distance_to(_ai_right_ray.get_collision_point())
	
	# Far side rays
	if _ai_far_left_ray and _ai_far_left_ray.is_colliding():
		left_blocked = true
		var d: float = global_transform.origin.distance_to(_ai_far_left_ray.get_collision_point())
		left_dist = min(left_dist, d)
	if _ai_far_right_ray and _ai_far_right_ray.is_colliding():
		right_blocked = true
		var d: float = global_transform.origin.distance_to(_ai_far_right_ray.get_collision_point())
		right_dist = min(right_dist, d)
	
	# Calculate avoidance steering
	if left_blocked and not right_blocked:
		avoid_steer = -self.max_steering_rad * 0.8  # Steer right
	elif right_blocked and not left_blocked:
		avoid_steer = self.max_steering_rad * 0.8  # Steer left
	elif left_blocked and right_blocked:
		# Both sides blocked - steer toward the side with more space
		if left_dist > right_dist:
			avoid_steer = self.max_steering_rad * 0.5
		else:
			avoid_steer = -self.max_steering_rad * 0.5
		should_slow = true
	
	# Apply throttle/brake
	if should_brake:
		self._acceleration = self.transform.basis.z * self.braking_power  # Brake (reverse direction)
	elif should_slow:
		self._acceleration = -self.transform.basis.z * self.pc_engine_power * 0.4
	elif wants_brake_for_turn:
		# Brake proportionally to how much we're over the desired corner speed
		var over: float = clamp((current_speed - desired_speed) / max(desired_speed, 1.0), 0.0, 1.0)
		self._acceleration = self.transform.basis.z * self.braking_power * (0.35 + 0.65 * over)
	
	# Combine path following with obstacle avoidance
	var final_steer: float = path_steer + avoid_steer
	return clamp(final_steer, -self.max_steering_rad, self.max_steering_rad)


# constructor
func _init():
	Global.race_car_registry[self] = true
	self.get_steering_angle = Callable(self, "_get_gravity_steering_angle") \
		if DisplayServer.is_touchscreen_available()  \
		else Callable(self, "_get_action_steering_angle")

# called when the node enters the scene tree for the first time.
func _ready():
	if not self.get_path_direction.is_null():
		set_ctx_rays()
	else:
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

func _input(event: InputEvent):
	if event.is_action_pressed("ui_select"):
		print_debug(global_position)
	if event.is_action_pressed("ui_focus_next"):
		next_camera_position()
	if event.is_action_pressed("ui_up"):
		play_engine_sound(ACCELERATE)
	if Input.is_action_just_released("ui_up") or event.is_action_pressed("ui_down"):
		play_engine_sound(BRAKING)

func _input_process():
	if not self.get_path_direction.is_null():
		self._steering_angle = _get_ctx_steering_angle()
		return

	self._steering_angle = self.get_steering_angle.call()
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
	set_velocity(self._velocity + self._acceleration * delta)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `-self.transform.basis.y`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	move_and_slide()
	self._velocity = velocity
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
		var prev := self.global_transform
		var normal: Vector3 = (front_ray_normal + back_ray_normal) / 2.0
		var target := prev
		target.basis.x = -target.basis.z.cross(normal)
		target.basis.y = normal
		target.basis = target.basis.orthonormalized()
		self.global_transform = prev.interpolate_with(target, self.align_interpolate_weight)


func set_label(txt: String):
	$TopLabel.text = txt
	$TopLabel.visible = true

func get_label() -> String:
	return $TopLabel.text
