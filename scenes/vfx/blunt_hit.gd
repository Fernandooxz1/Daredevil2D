class_name BluntHit
extends GPUParticles2D

## Efecto de impacto contuso seco y sutil para ataques de ladrones/enemigos.
## 100% monocromático (sin sangre), con micro-chispas de impacto seco.
## Configurado con one_shot = true y auto-destrucción al terminar con finished.

func _ready() -> void:
	finished.connect(queue_free)
	emitting = true

## Orienta las micro-chispas en la dirección del impacto
func set_hit_direction(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()

## Método utilitario estático para instanciar el impacto contuso
static func spawn(parent: Node, global_pos: Vector2, hit_dir: Vector2 = Vector2.ZERO) -> BluntHit:
	var scene := load("res://scenes/vfx/blunt_hit.tscn") as PackedScene
	if not scene:
		return null
	var instance := scene.instantiate() as BluntHit
	parent.add_child(instance)
	instance.global_position = global_pos
	if hit_dir != Vector2.ZERO:
		instance.set_hit_direction(hit_dir)
	return instance
