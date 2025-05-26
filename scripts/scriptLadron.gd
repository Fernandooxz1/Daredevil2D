extends CharacterBody2D

@export var gravity := 1200
@export var speed := 130
@export var attack_range := 45
@export var detection_range := 450

var state: String = "idle"
var took_hit : float = 0
var is_dead := false
var can_attack := true
var is_attacking := false
var stun_timer := 0.0
var is_stunned := false

@onready var player: Node2D = get_parent().get_node("Daredevil")
@onready var corazoncito = preload("res://scenes/items/heart.tscn")
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var Colision = $CollisionShape2D

func _ready():
	hitbox.disabled = true
	_stop("idle")
	
func _physics_process(delta):
	
	var distance = abs(player.position.x - position.x)
	var direction = sign(player.global_position.x - global_position.x)
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if is_dead:
		_stop("dead")
		Colision.disabled = true
		queue_free()
		return

	# Si está aturdido
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		move_and_slide()
		return

	_update_facing(direction)

	if distance <= attack_range:
		attack(direction)
	elif distance <= detection_range and distance >= attack_range - 5:
		velocity.x = direction * speed
	else:
		_stop("idle")
		

	move_and_slide()

func _stop(anim: String):
	velocity.x = 0
	animation.play(anim)

func _update_facing(direction: int):
	if direction != 0 and sign(direction) != sign(animation.scale.x):
		animation.scale.x *= -1

func attack(direction: int) -> void:
	if is_attacking or not can_attack:
		return

	is_attacking = true
	can_attack = false

	velocity.x = 0
	animation.play("attack")

	hitbox.position.x = 30 * direction
	hitbox.disabled = false
	await get_tree().create_timer(0.1).timeout
	hitbox.disabled = true

	await animation.animation_finished
	await get_tree().create_timer(0.5).timeout

	can_attack = true
	is_attacking = false


func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health


func _on_health_component_on_damage_took(daño) -> void:
	if is_stunned:
		return
	is_stunned = true
	stun_timer = clamp(daño * 0.0, 0.1, 1.0)
	_stop("take_damage")

func _on_health_component_on_dead() -> void:
	is_dead = true
	$HealthComponent/CollisionShape2D.disabled = true
	crear(corazoncito, Vector2(0, -10))

func crear(sce, offset: Vector2):
	var inst = sce.instantiate()
	get_parent().add_child(inst)
	inst.global_position = global_position + offset
