class_name Forest
extends MeshInstance

const Tree := preload("res://circuits/tree_large.tscn")

export(int) var count = 0
export(int) var max_tree_size = 5

onready var size: Vector2 = (mesh as PlaneMesh).size


func _init():
	randomize()


func _ready():
	var w := self.size.x/2
	var h := self.size.y/2
	for i in self.count:
		var tree := Tree.instance()
		add_child(tree)
		tree.global_translate(Vector3(rand_range(-w, w), 0.0, rand_range(-h, h)))
		tree.global_scale(Vector3(rand_range(1, self.max_tree_size), rand_range(1, self.max_tree_size), rand_range(1, self.max_tree_size)))


