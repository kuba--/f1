class_name OptionsPopup
extends PopupPanel

func _ready():
	$Container/EnginePowerContainer/HSlider.value = Global.engine_power
	$Container/PCEnginePowerContainer/HSlider.value = Global.pc_engine_power
	$Container/BrakingPowerContainer/HSlider.value = Global.braking_power
	$Container/MaxSpeedReverseContainer/HSlider.value = Global.max_speed_reverse
	$Container/MinSpeedDriftingContainer/HSlider.value = Global.min_speed_drifting
	$Container/FrictionCoefficientContainer/HSlider.value = Global.friction_coefficient
	$Container/DragCoefficientContainer/HSlider.value = Global.drag_coefficient
	$Container/TractionCoefficientContainer/HSlider.value = Global.traction_coefficient
	$Container/TractionDriftingCoefficientContainer/HSlider.value = Global.traction_drifting_coefficient
	$Container/MaxSteeringAngleContainer/HSlider.value = Global.max_steering_angle
	$Container/GravitySteeringCoefficientContainer/HSlider.value = Global.gravity_steering_coefficient
	$Container/LapsCount/HSlider.value = Global.laps_count


func _set_value(label: Label, value: float, fmt: String = "%.2f"):
	label.text = ("(" + fmt + ")") % value


func _on_engine_power_value_changed(value: float):
	_set_value($Container/EnginePowerContainer/Container/Value, value)
	Global.engine_power = value

func _on_pc_engine_power_value_changed(value: float):
	_set_value($Container/PCEnginePowerContainer/Container/Value, value)
	Global.pc_engine_power = value


func _on_braking_power_value_changed(value: float):
	_set_value($Container/BrakingPowerContainer/Container/Value, value)
	Global.braking_power = value


func _on_max_speed_reverse_value_changed(value: float):
	_set_value($Container/MaxSpeedReverseContainer/Container/Value, value)
	Global.max_speed_reverse = value


func _on_min_speed_drifting_value_changed(value: float):
	_set_value($Container/MinSpeedDriftingContainer/Container/Value, value)
	Global.min_speed_drifting = value


func _on_friction_value_changed(value: float):
	_set_value($Container/FrictionCoefficientContainer/Container/Value, value)
	Global.friction_coefficient = value


func _on_drag_value_changed(value: float):
	_set_value($Container/DragCoefficientContainer/Container/Value, value)
	Global.drag_coefficient = value


func _on_traction_value_changed(value: float):
	_set_value($Container/TractionCoefficientContainer/Container/Value, value)
	Global.traction_coefficient = value


func _on_traction_drifting_value_changed(value: float):
	_set_value($Container/TractionDriftingCoefficientContainer/Container/Value, value)
	Global.traction_drifting_coefficient = value


func _on_max_steering_angle_value_changed(value: float):
	_set_value($Container/MaxSteeringAngleContainer/Container/Value, value, "%d")
	Global.max_steering_angle = value


func _on_gravity_steering_value_changed(value: float):
	_set_value($Container/GravitySteeringCoefficientContainer/Container/Value, value)
	Global.gravity_steering_coefficient = value


func _on_laps_count_value_changed(value: float):
	_set_value($Container/LapsCount/Container/Value, value)
	Global.laps_count = value

