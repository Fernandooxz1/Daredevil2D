extends Area2D
class_name HealthComponent

signal on_dead
signal on_damage_took(damage_amount: int)
signal on_health_changed(health: int)
signal on_hit_received(hit_data: Dictionary)

@export var max_health: int = 100
var current_health: int = 0
var last_hit_data: Dictionary = {}

func _ready() -> void:
	current_health = max_health

func take_heal(value: int) -> void:
	_set_health(value)

func take_damage(damage: int, hit_data: Dictionary = {}) -> void:
	last_hit_data = hit_data
	var target = owner if (owner and owner.has_method("intercept_damage")) else (get_parent() if (get_parent() and get_parent().has_method("intercept_damage")) else null)
	if target:
		damage = target.intercept_damage(damage, hit_data)
		if damage <= 0:
			return # Mitigado por parry o bloqueo
	var value = abs(damage)
	_set_health(-value)
	if not hit_data.is_empty():
		on_hit_received.emit(hit_data)

func _set_health(value: int) -> void:
	var old_health = current_health
	current_health = clamp(current_health + value, 0, max_health)

	if old_health != current_health:
		on_health_changed.emit(current_health)
	if current_health <= 0:
		_die()
		return
	elif current_health < old_health:
		on_damage_took.emit(-value)

func _die() -> void:
	on_dead.emit()
