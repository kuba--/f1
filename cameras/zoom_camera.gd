class_name ZoomCamera
extends Camera

signal camera_position_set

export(float, 0.1, 1.0) var lerp_speed = 0.50
export(float, 1.1, 2.0) var max_lerp_speed = 1.5
export(float, 1.0e-5, 1.0e-2) var y_epsilon = 1.0e-3

var position: Position3D = null
var _is_equal: bool = false

func _physics_process(delta: float):
	if self._is_equal or not self.position:
		return

	global_transform = global_transform.interpolate_with(self.position.global_transform, self.lerp_speed * delta)
	if global_transform.basis.y.distance_to(self.position.global_transform.basis.y) < self.y_epsilon \
	and (self.lerp_speed < self.max_lerp_speed):
		self.lerp_speed = min(self.lerp_speed + delta, self.max_lerp_speed)
	self._is_equal = global_transform.basis.is_equal_approx(self.position.global_transform.basis)
	if self._is_equal:
		emit_signal("camera_position_set")

