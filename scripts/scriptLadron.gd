extends CharacterBody2D

@export var gravity := 1200
@export var speed := 130
@export var attack_range := 45
@export var detection_range := 450
@export var cooldown_time: float = 0.75

var state: String = "idle"
var took_hit := false
var is_dead := false
var can_attack := true

@onready var player: Node2D = get_parent().get_node("Daredevil")
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $HitboxComponent/CollisionShape2D

func _ready():
	hitbox.disabled = true

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		_stop("idle")
		return

	if took_hit:
		_play_hit_animation()
		return

	var distance = abs(player.position.x - position.x)
	var direction = sign(player.global_position.x - global_position.x)

	_update_facing(direction)

	if distance <= attack_range and can_attack:
		attack(direction)
	elif distance <= detection_range:
		velocity.x = direction * speed
		#animation.play("run")
	else:
		_stop("idle")

	move_and_slide()

func _stop(anim: String):
	velocity.x = 0
	animation.play(anim)

func _update_facing(direction: int):
	if direction != 0 and sign(direction) != sign(animation.scale.x):
		animation.scale.x *= -1

func _play_hit_animation():
	_stop("take_damage")
	took_hit = false
	await get_tree().create_timer(0.2).timeout

func attack(direction: int):
	can_attack = false
	_stop("attack")
	hitbox.position.x = 30 * direction
	hitbox.disabled = false
	await get_tree().create_timer(0.1).timeout
	hitbox.disabled = true
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health

func _on_health_component_on_damage_took() -> void:
	took_hit = true

func _on_health_component_on_dead() -> void:
	is_dead = true
