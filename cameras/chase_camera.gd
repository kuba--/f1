class_name ChaseCamera
extends Camera

export(bool) var fixed = false
export(float) var lerp_speed = 6.0

var _position: Position3D = null

func _physics_process(delta: float):
	if not self._position:
		return

	global_transform = self._position.global_transform if self.fixed \
	else global_transform.interpolate_with(self._position.global_transform, self.lerp_speed * delta)


func _on_camera_position_changed(pos: Position3D):
	self._position = pos
