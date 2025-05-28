extends CharacterBody2D

# === EXPORT VARIABLES ===
@export var gravity := 1200
@export var speed := 130
@export var attack_range := 45
@export var detection_range := 450

# === STATE VARIABLES ===
var state: String = "idle"
var took_hit: float = 0
var is_dead := false
var can_attack := true
var is_attacking := false
var stun_timer := 0.0
var is_stunned := false


# === NODE REFERENCES ===
@onready var player: Node2D = get_parent().get_node("Daredevil")
@onready var corazoncito = preload("res://scenes/items/heart.tscn")
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var healthbox: CollisionShape2D = $HealthComponent/CollisionShape2D
@onready var Colision = $CollisionShape2D
@onready var direction = 1

# === READY ===
func _ready():
	hitbox.disabled = true
	_stop("idle")

# === MAIN LOOP ===
func _physics_process(delta):
	# var distance = abs(player.position.x - position.x)
	# direction = sign(player.global_position.x - global_position.x)
	direction = sign(player.position.x - position.x)
	var distance = abs(player.position.x - position.x)
		
	# Aplicar gravedad si está en el aire
	if not is_on_floor():
		velocity.y += gravity * delta

	# Si está muerto
	if is_dead:
		_stop("dead")
		Colision.disabled = true
		queue_free()
		return

	# Si está aturdido
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.40: # terminar knockback
			velocity.x = 0
		if stun_timer <= 0:
			is_stunned = false
			is_attacking = false
			can_attack = true
			_stop("idle")
		move_and_slide()
		return

	# Dirección y detección
	_update_facing(direction)

	if distance <= attack_range:
		attack(direction)
	elif distance <= detection_range and distance >= attack_range - 5:
		velocity.x = direction * speed
	else:
		_stop("idle")

	move_and_slide()

# === HELPER FUNCTIONS ===
func _stop(anim: String):
	if animation.animation != anim:
		animation.play(anim)
	velocity.x = 0

func _update_facing(direction: int):
	if direction != 0 and sign(direction) != sign(animation.scale.x):
		animation.scale.x *= -1

# === ATTACK LOGIC ===
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
	if is_stunned:
		end_attack_early()
		return

	hitbox.disabled = true
	await animation.animation_finished
	if is_stunned:
		end_attack_early()
		return

	await get_tree().create_timer(0.1).timeout
	if is_stunned:
		end_attack_early()
		return

	can_attack = true
	is_attacking = false

func end_attack_early():
	hitbox.disabled = true
	is_attacking = false
	can_attack = true

# === HEALTH EVENTS ===
func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health

func _on_health_component_on_damage_took(daño) -> void:
	if is_stunned:
		return
	is_stunned = true
	_stop("take_damage")
	velocity.x = -sign(direction) * 100 #knockback
	stun_timer = clamp(daño * 0.025, 0.1, 1)
	# print("daño: ", daño,"  stun: ", daño * 0.025)

func _on_health_component_on_dead() -> void:
	is_dead = true
	healthbox.disabled = true
	crear(corazoncito, Vector2(0, -10))

# === DROP CREATION ===
func crear(sce, offset: Vector2):
	var inst = sce.instantiate()
	get_parent().add_child(inst)
	inst.global_position = global_position + offset
