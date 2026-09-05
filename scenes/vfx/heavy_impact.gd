class_name HeavyImpact
extends GPUParticles2D

## Efecto de partículas para remates pesados (Golpe 4 Uppercut y Patada).
## Combina un anillo de choque expansivo (shockwave ring) con un estallido
## masivo de chispas angulares blanco brillante y rojo carmesí de alta energía.
## Configurado con one_shot = true y auto-destrucción con finished.

@onready var shockwave: GPUParticles2D = get_node_or_null("Shockwave")

func _ready() -> void:
	finished.connect(queue_free)
	emitting = true
	if shockwave:
		shockwave.emitting = true

## Orienta las chispas pesadas en la dirección del golpe fuerte
func set_hit_direction(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()

## Método utilitario estático para instanciar el remate pesado
static func spawn(parent: Node, global_pos: Vector2, hit_dir: Vector2 = Vector2.ZERO) -> HeavyImpact:
	var scene := load("res://scenes/vfx/heavy_impact.tscn") as PackedScene
	if not scene:
		return null
	var instance := scene.instantiate() as HeavyImpact
	parent.add_child(instance)
	instance.global_position = global_pos
	if hit_dir != Vector2.ZERO:
		instance.set_hit_direction(hit_dir)
	return instance
