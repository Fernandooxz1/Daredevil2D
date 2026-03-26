extends Area2D
class_name HealthComponent

signal on_dead
signal on_damage_took(damage_amount: int)
signal on_health_changed(health: int)

@export var max_health: int = 100
var current_health: int = 0

func _ready() -> void:
	current_health = max_health

func take_heal(value: int):
	_set_health(value)

func take_damage(damage: int):
	var value = abs(damage)
	_set_health(-value)

func _set_health(value: int):
	var old_health = current_health
	current_health = clamp(current_health + value, 0, max_health)

	if old_health != current_health:
		on_health_changed.emit(current_health)
	if current_health <= 0:
		_die()
		return
	elif current_health < old_health:
		on_damage_took.emit(-value)

func _die():
	on_dead.emit()
