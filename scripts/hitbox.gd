extends Area2D
class_name HitboxComponent

@export var damage: int = 2

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if area is HealthComponent:
		area.take_damage(damage)

func _on_health_component_on_dead() -> void:
	pass
