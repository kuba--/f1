class_name ChaseCamera
extends Camera3D

@export var fixed: bool = false
@export var lerp_speed: float = 6.0

var _position: Marker3D = null

func _physics_process(delta: float):
	if not self._position:
		return

	global_transform = self._position.global_transform if self.fixed \
	else global_transform.interpolate_with(self._position.global_transform, self.lerp_speed * delta)


func _on_camera_position_changed(pos: Marker3D):
	self._position = pos
