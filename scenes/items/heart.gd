extends Area2D
class_name itemComponent

@export var cura: int = 10

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))
	$"../AnimationPlayer".play("moving")

func _on_area_entered(area: Area2D) -> void:
	if area is HealthComponent:
		area.take_heal(cura)
		$"..".queue_free()
