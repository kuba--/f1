extends Node

var _params: Dictionary = {} setget , get_params

func change_scene_to(packed_scene: PackedScene, params=null):
	self._params = params
	var err := get_tree().change_scene_to(packed_scene)
	assert(err == OK, "change_scene_to error %d" % err)

func change_scene(path: String, params: Dictionary = {}):
	self._params = params
	var err := get_tree().change_scene(path)
	assert(err == OK, "change_scene %s error %d" % [path, err])

func get_params() -> Dictionary:
	return _params
