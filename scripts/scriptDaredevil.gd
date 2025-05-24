extends CharacterBody2D

signal actual_weapon

@export var gravity := 1200
@export var speed := 200

var Egen : int = 1
var jump_speed := 600
var acceleration := 1000
var friction := 4500
var run_multiplier := 2.0
var is_dead := false
var already_dead := false
var arma_actual : int = 1 # 1 = puños, 2 = bastón, 3 = duales
var facing := 1

@onready var red_suite = $RedSuite
@onready var hitbox = $HitboxComponent/HitShapeDD
@onready var health_shape = $HealthComponent/HealthShapeDD
@onready var health_comp = $HealthComponent
@onready var collision = $CollisionDD
@onready var Ebar = $Camera2D2/HUD/EnergyBar
@onready var Rbar = $Camera2D2/HUD/RageBar



const GAME_OVER_SCENE_PATH := "res://scenes/gameover.tscn"

func _ready() -> void:
	
	hitbox.disabled = true
	health_shape.disabled = false
	Rbar.value = 0
	Ebar.value = 100
	$HealthComponent.onDamageTook.connect(on_damage_took)

func _on_dead() -> void:
	is_dead = true

func _physics_process(delta):
	var is_grounded := is_on_floor()
	var direction := Input.get_axis("left", "right")
	var is_running := Input.is_action_pressed("run")
	var is_attacking := Input.is_action_pressed("attack")
	var jump_pressed := Input.is_action_just_pressed("jump") and is_grounded
	var is_crouching := Input.is_action_pressed("crouch")
	var is_blocking := Input.is_action_pressed("blokear")
	var change_weapon := Input.is_action_just_pressed("Cambiar Arma")


# reloj de generacion de 1 punto de energia
	Egen = Egen + 1
	if Egen > 10:
		Egen = 0
	# Barra de Energia
	if Egen == 10:
		Ebar.value = Ebar.value + 1
		if Ebar.value > 100:
			Ebar.value = 100
		
	print("Ebar.value: ",Ebar.value,"    Rbar.value: ",Rbar.value)
	
	if not is_grounded:
		velocity.y += gravity * delta

	if is_dead:
		_process_death()
		return

	if change_weapon:
		arma_actual += 1
		if arma_actual > 3:
			arma_actual = 1
		actual_weapon.emit(arma_actual)

	if jump_pressed and Ebar.value > 0:
		velocity.y = -jump_speed
		quitar_energia(1,10)

	if is_crouching and is_grounded:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif direction != 0:
		facing = sign(direction)
		@warning_ignore("incompatible_ternary")
		var target_speed = speed * (run_multiplier if is_running and (Ebar.value > 20) else 1)
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		if target_speed == speed * run_multiplier:
			quitar_energia(0,2)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	_update_animation(is_blocking, is_grounded, direction, is_running, is_attacking, is_crouching)

	move_and_slide()

# -------------------- Animación y Visuales --------------------

func _update_animation(is_blocking, is_grounded: bool, direction: float, is_running: bool, is_attacking: bool, is_crouching: bool) -> void:
	var anim = "idle"
	var sprite_scale = Vector2(facing * 2.2, 2.0)
	var sprite_pos = Vector2.ZERO
	var collision_scale = Vector2(50, 65)
	var collision_pos = Vector2.ZERO

	# Idle básico por arma
	match arma_actual:
		1:
			anim = "idle"
			set_health_shape(Vector2.ZERO, Vector2(15, 30))
		2:
			anim = "baston_idle"
			set_health_shape(Vector2(-200 * facing, 0), Vector2(15, 30))
		3:
			anim = "idle" # Cambiar por "idle_dual"
			set_health_shape(Vector2.ZERO, Vector2(15, 30))

	# Movimiento
	if not is_grounded:
		anim = "jump_hit" if is_attacking and Ebar.value > 0 else "jump"
		sprite_scale = Vector2(facing * 0.975, 0.975)
		if is_attacking and Ebar.value > 0 :
			await activar_hitbox(Vector2(420 * facing, 200))
			quitar_energia(1,1)
	elif is_crouching:
		if is_attacking:
			anim = "crouch_hit"
			sprite_scale = Vector2(facing * 2.6, 2.5)
			sprite_pos = Vector2(facing * 50, 150)
			set_health_shape(Vector2(0, 150), Vector2(15, 25))
			await activar_hitbox(Vector2(450 * facing, -100))
			quitar_energia(1,1)
		else:
			anim = "crouch"
			sprite_scale = Vector2(facing * 0.85, 0.8)
			sprite_pos = Vector2(0, 150)
			set_health_shape(Vector2(0, 150), Vector2(15, 25))
	elif direction == 0:
		if is_attacking and Ebar.value > 0 :
			match arma_actual:
				1:
					anim = "hit"
					sprite_scale = Vector2(facing * 0.9, 1.0)
					await activar_hitbox(Vector2(350 * facing, -200))
					quitar_energia(1,1)
				2:
					anim = "hit_baston"
					sprite_scale = Vector2(facing * 2, 2)
					set_health_shape(Vector2(0, 0), Vector2(15, 30))
					await activar_hitbox(Vector2(475 * facing, -175))
					quitar_energia(1,1)
		elif is_blocking and Ebar.value > 0:
			anim = "idle" # Cambiar por "blocking"
			sprite_scale = Vector2(facing * 2.3, 2)
			health_shape.disabled = true
	else:
		anim = "run" if is_running and Ebar.value > 20 else "walk"
		sprite_scale = Vector2(facing * (2.2 if is_running else 1.6), 2.2 if is_running else 1.5)

	# Aplicar valores finales
	red_suite.play(anim)
	red_suite.position = sprite_pos
	red_suite.scale = sprite_scale
	collision.position = collision_pos
	collision.scale = collision_scale

# -------------------- Utilidades Healtbox y Hitbox --------------------
func quitar_energia(D_act_rel,cansancio):
	Egen = Egen + 1
	if Egen > 10:
		Egen = 0
	if Egen == 10 or D_act_rel:
		Ebar.value = Ebar.value - cansancio
	if Ebar.value < -15:
		Ebar.value = -15
	
func on_damage_took() -> void:
	Enojarse(1)

func Enojarse(ira):
	Rbar.value = Rbar.value + ira
	if Rbar.value > 100:
		Rbar.value = 100
	
@warning_ignore("shadowed_variable_base_class")
func set_health_shape(pos: Vector2, scale: Vector2) -> void:
	health_shape.disabled = false
	health_shape.position = pos
	health_shape.scale = scale

func activar_hitbox(pos: Vector2, tiempo := 0.1) -> void:
	hitbox.position = pos
	hitbox.disabled = false
	await get_tree().create_timer(tiempo).timeout
	hitbox.disabled = true

# -------------------- Muerte --------------------

func _process_death() -> void:
	red_suite.position = Vector2.ZERO
	red_suite.scale = Vector2(2.3 * facing, 2.3)
	collision.position = Vector2.ZERO
	collision.scale = Vector2(50, 50)

	if not already_dead:
		red_suite.play("dead")
		await red_suite.animation_finished
		already_dead = true
	else:
		red_suite.play("morido")
		red_suite.scale = Vector2(2.5 * facing, 2.5)
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)
