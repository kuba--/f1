class_name StatsPopup
extends PopupDialog

const Main: PackedScene = preload("res://main.tscn")

onready var _result_containers: Array = [
	$VBoxContainer/ResultsContainer/VBoxContainer/P1Container,
	$VBoxContainer/ResultsContainer/VBoxContainer/P2Container,
	$VBoxContainer/ResultsContainer/VBoxContainer/P3Container,
	$VBoxContainer/ResultsContainer/VBoxContainer/P4Container
]

var _icon: Texture = null

# Array [
# 	{ "icon" => Texture, "label" => String, "total" => [ float, float, float ], "disqualified" => bool }
# ]
var _results: Array = []

func init(icon: Texture, results: Array):
	self._icon = icon
	self._results = results


func _ready():
	popup_exclusive = true
	$VBoxContainer/SettingsPanel/HBoxContainer/Icon.texture = self._icon
	$VBoxContainer/SettingsPanel/HBoxContainer/Icon.visible = true
	for p in range(len(self._results)):
		_set_result(p, self._results[p] as Dictionary)


func _set_result(p: int, r: Dictionary):
	assert(r.icon != null, "icon is null")
	assert(r.label != null, "label is null")
	assert(r.total != null, "total is null")
	var container := self._result_containers[p] as HBoxContainer
	container.get_node("Icon").texture = r.icon
	container.get_node("Label").text = r.label
	if r.disqualified:
		container.get_node("Total").text = "DQ"
	else:
		container.get_node("Total").text = ("%07.3f" % r.total[2]) + ((" (+ %.1f)" % r.total[1]) if r.total[1] > 0.0 else "")
	container.visible = true


func _on_home_pressed():
	var err := get_tree().change_scene_to(Main)
	assert(err == OK, "change_scene_to error %d" % err)
