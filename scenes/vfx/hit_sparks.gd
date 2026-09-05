class_name HitSparks
extends GPUParticles2D

## Sistema de partículas de impacto de combate (Hit Sparks).
## Emite un estallido cónico de chispas angulares blanco brillante con reborde rojo carmesí.
## Configurado con one_shot = true, explosiveness = 0.92 y auto-destrucción con finished.

func _ready() -> void:
	finished.connect(queue_free)
	emitting = true

## Orienta el estallido en la dirección del impacto (ej: Vector2.RIGHT o normal)
func set_hit_direction(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()

## Método utilitario estático para instanciar y posicionar fácilmente
static func spawn(parent: Node, global_pos: Vector2, hit_dir: Vector2 = Vector2.ZERO) -> HitSparks:
	var scene := load("res://scenes/vfx/hit_sparks.tscn") as PackedScene
	if not scene:
		return null
	var instance := scene.instantiate() as HitSparks
	parent.add_child(instance)
	instance.global_position = global_pos
	if hit_dir != Vector2.ZERO:
		instance.set_hit_direction(hit_dir)
	return instance
