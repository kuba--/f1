class_name LapPanel
extends PanelContainer

onready var count_label := $Container/CountLabel
onready var penalty_label := $Container/PenaltyLabel
onready var time_label := $Container/TimeLabel

func set_lap(idx: int, penalty: float, time: float):
	self.count_label.text = ("%d:" % idx)
	self.penalty_label.text = ("(+ %.1f)" % penalty) if penalty > 0.0 else ""
	self.time_label.text = ("%07.3f" % time)
