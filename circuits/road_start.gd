class_name RoadStart
extends Area

signal lights_out

enum {
	GLASS = 0,
	RED,
	YELLOW,
	GREEN
}

export(Array, Material) var lights_materials = [
	preload("res://assets/materials/glass.material"),
	preload("res://assets/materials/red.material"),
	preload("res://assets/materials/pylon.material"),
	preload("res://assets/materials/grass.material"),
]

const LIGHTS_MESH_SURFACE: int = 2

onready var lights_mesh: MeshInstance = $Lights/Mesh
onready var lights_timer: Timer = $Lights/Timer
onready var lights_sound: AudioStreamPlayer = $Lights/Sound

var _lights_timer_ticks: int = 0

func _ready():
	lights_mesh.set_surface_material(LIGHTS_MESH_SURFACE, lights_materials[GLASS])


func _on_lights_timer_timeout():
	_lights_timer_ticks += 1
	match _lights_timer_ticks:
		GLASS:
			pass
		RED, YELLOW, GREEN:
			lights_mesh.set_surface_material(LIGHTS_MESH_SURFACE, lights_materials[_lights_timer_ticks])
			lights_sound.play()
		_:
			lights_timer.stop()
			emit_signal("lights_out")
