extends Area2D
class_name HitboxComponent #daño

@export var damage :int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(hit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func hit(area):
	if area is HealthComponent:
		area.take_damage(damage)


func _on_health_component_on_dead() -> void:
	pass # Replace with function body.
