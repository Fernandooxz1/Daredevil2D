extends Area2D
class_name HealthComponent #vida

signal onDead
signal onDamageTook
signal onHealthChanged(health: int)

@export var max_health: int = 100
var current_health : int = 0
var old_health : int

func _ready() -> void:
	
	current_health = max_health

func take_heal(value: int):
	set_health(value)

func take_damage(damage: int):
	var value = abs(damage)
	set_health(-value)

func set_health(value: int):
	old_health = current_health
	current_health = current_health + value
	current_health = clamp (current_health,0,max_health)
	
	if old_health != current_health:
		onHealthChanged.emit(current_health)
	if current_health <= 0:
		dead()
		return
	elif current_health >= 0 and current_health < old_health :
		onDamageTook.emit()

func dead():
	onDead.emit()
