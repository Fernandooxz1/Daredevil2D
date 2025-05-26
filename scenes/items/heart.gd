extends Area2D
class_name itemComponent #daño

@export var cura :int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(curar)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func curar(area):
	if area is HealthComponent:
		area.take_heal(cura)
		$"..".queue_free()
