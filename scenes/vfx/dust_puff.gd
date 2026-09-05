class_name DustPuff
extends GPUParticles2D

## Polvo y humo sutil de pisada, derrape al cambiar de dirección y aterrizaje.
## Partículas suaves en gris claro/blanco translúcido que flotan y se desvanecen hacia arriba.
## Configurado con one_shot = true y auto-destrucción con finished.

func _ready() -> void:
	finished.connect(queue_free)
	emitting = true

## Orienta ligeramente la bocanada según la dirección del movimiento
func set_facing(facing_dir: float) -> void:
	if facing_dir != 0.0:
		scale.x = abs(scale.x) * sign(facing_dir)

## Método utilitario estático para instanciar en pies/suelo
static func spawn(parent: Node, global_pos: Vector2, offset: Vector2 = Vector2.ZERO) -> DustPuff:
	var scene := load("res://scenes/vfx/dust_puff.tscn") as PackedScene
	if not scene:
		return null
	var instance := scene.instantiate() as DustPuff
	parent.add_child(instance)
	instance.global_position = global_pos + offset
	return instance
