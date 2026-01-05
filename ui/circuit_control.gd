class_name CircuitControl
extends Control

const MainScene: PackedScene = preload("res://main.tscn")
const LapPanelScene: PackedScene = preload("res://ui/lap_panel.tscn")

@onready var time_label := $TimePanel/Container/TimeContainer/Label
@onready var lap_container := $SettingsLapContainer/LapContainer
@onready var lap_label := $TimePanel/Container/LapLabel

var _lap_count: int = 0

func _ready():
	$ControlContainer.visible = DisplayServer.is_touchscreen_available()


func init(laps_count: int):
	self._lap_count = laps_count
	self.time_label.text = ("%07.3f" % 0.0)
	self.lap_label.text = ("1/%d" % self._lap_count)


func set_time_elapsed(time_elapsed: float):
	self.time_label.text = ("%07.3f" % time_elapsed)


func set_lap_idx(lap_idx: int):
	self.lap_label.text = ("%d/%d" % [lap_idx + 1, self._lap_count])


func set_lap(lap_idx: int, lap_penalty: float, lap_time: float):
	var lap_panel: LapPanel
	if lap_idx >= self.lap_container.get_child_count():
		lap_panel = LapPanelScene.instantiate()
		self.lap_container.add_child(lap_panel)
	else:
		lap_panel = self.lap_container.get_child(lap_idx)
	lap_panel.set_lap(lap_idx + 1, lap_penalty, lap_time)


func _on_home_pressed():
	var err := get_tree().change_scene_to_packed(MainScene)
	assert(err == OK, "change_scene_to_packed error %d" % err)

