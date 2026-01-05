class_name Forest
extends MeshInstance3D

const TreeScene := preload("res://circuits/tree_large.tscn")

@export var count: int = 0
@export var max_tree_size: int = 5

@onready var size: Vector2 = (mesh as PlaneMesh).size


func _init():
	randomize()


func _ready():
	var w := self.size.x/2
	var h := self.size.y/2
	for i in self.count:
		var tree := TreeScene.instantiate()
		add_child(tree)
		tree.global_translate(Vector3(randf_range(-w, w), 0.0, randf_range(-h, h)))
		tree.global_scale(Vector3(randf_range(1, self.max_tree_size), randf_range(1, self.max_tree_size), randf_range(1, self.max_tree_size)))


