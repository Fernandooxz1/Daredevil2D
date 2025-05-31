extends CharacterBody2D

signal actual_weapon

@export var gravity := 1200
@export var speed := 200

# --- Estado y energía ---
var Egen: int = 1
var Rdegen: int = 1
var senojo: int = 0
var enojado: int = 0
var is_dead := false
var already_dead := false
var arma_actual: int = 1
var facing := 1

# Relojes
var AttackClock : int = 0

# Flags
var is_attackanding = false
var anim_fin = false
var is_attacking := false
var combo_step := 0
var can_combo := false

# --- Movimiento ---
var jump_speed := 600
var acceleration := 1000
var friction := 4500
var run_multiplier := 2.0
var relojitodigo = 0
var sholodigo = 1

# --- Referencias ---
@onready var combo_timer := $ComboTimer  # Agrega un Timer hijo del personaje y conéctalo
@onready var red_suite = $RedSuite
@onready var hitboxC = $HitboxComponent
@onready var hitbox = $HitboxComponent/HitShapeDD
@onready var health_shape = $HealthComponent/HealthShapeDD
@onready var health_comp = $HealthComponent
@onready var collision = $CollisionDD
@onready var Ebar = $Camera2D2/HUD/EnergyBar
@onready var Rbar = $Camera2D2/HUD/RageBar
@onready var anim = "idle"

const GAME_OVER_SCENE_PATH := "res://scenes/gameover.tscn"

func _ready() -> void:
	hitbox.disabled = true
	health_shape.disabled = false
	Rbar.value = 0
	Ebar.value = 100
	health_comp.onDamageTook.connect(on_damage_took)
	health_comp.onHealthChanged.connect(on_health_changed)

func _on_dead() -> void:
	is_dead = true

func _physics_process(delta):
	var is_grounded := is_on_floor()
	var direction := Input.get_axis("left", "right")
	var is_running := Input.is_action_pressed("run")
	var ataco := Input.is_action_just_pressed("attack")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var is_crouching := Input.is_action_pressed("crouch")
	var is_blocking := Input.is_action_pressed("blokear")
	var change_weapon := Input.is_action_just_pressed("Cambiar Arma")


	# Rutina de Combos
	if ataco:
		if !is_attacking:
			_start_combo_attack(1)
		elif can_combo:
			_start_combo_attack(combo_step + 1)

	# Regeneración de energía
	Egen += 1
	if Egen > 10:
		Egen = 0
	if Egen == 10:
		Ebar.value = min(Ebar.value + 1, 100)

	if not is_grounded:
		velocity.y += gravity * delta

	if is_dead:
		_process_death()
		return

	if change_weapon:
		arma_actual = arma_actual % 3 + 1
		actual_weapon.emit(arma_actual)

	# Saltos
	if jump_pressed and is_on_wall() and Ebar.value > 0 and is_running and not is_grounded:
		velocity.x = 600 * -facing
		velocity.y = -jump_speed
		quitar_energia(1, 10)
	elif jump_pressed and is_grounded and Ebar.value > 0:
		velocity.y = -jump_speed
		quitar_energia(1, 10)

	# Movimiento
	if is_crouching and is_grounded:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif direction != 0:
		facing = sign(direction)
		run_multiplier = 2.0 if Ebar.value > 40 else 1.25
		var target_speed = speed * (run_multiplier if is_running and Ebar.value > 20 else 0.75)
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		if target_speed == speed * run_multiplier:
			quitar_energia(0, 2)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Animaciones y estado
	_update_animation(is_blocking, is_grounded, direction, is_running, is_attacking, is_crouching)
	_update_damage(anim,arma_actual)
	senojo = _detectar_enojo()
	Enojado(senojo)
	move_and_slide()

# -------------------- Animación --------------------

func _update_animation(is_blocking, is_grounded: bool, direction: float, is_running: bool, is_attacking: bool, is_crouching: bool) -> void:
	self.anim = "idle"
	var sprite_scale = Vector2(facing * 2.2, 2.0)
	var sprite_pos = Vector2.ZERO
	var collision_scale = Vector2(50, 65)
	var collision_pos = Vector2.ZERO

	match arma_actual:
		1:
			anim = "idle"
			set_health_shape(Vector2.ZERO, Vector2(15, 30))
		2:
			anim = "baston_idle"
			set_health_shape(Vector2.ZERO, Vector2(15, 30))
		3:
			anim = "idle"
			set_health_shape(Vector2.ZERO, Vector2(15, 30))

	# Animaciones según el estado
	if not is_grounded:
		anim = "jump_hit" if is_attacking and Ebar.value > 0 else "jump"
		sprite_scale = Vector2(facing * 0.975, 0.975)
	elif is_crouching:
		anim = "crouch_hit" if is_attacking else "crouch"
		sprite_scale = Vector2(facing * (2.6 if is_attacking else 0.85), 2.5 if is_attacking else 0.8)
		sprite_pos = Vector2(facing * 50, 150) if is_attacking else Vector2(0, 150)
		set_health_shape(Vector2(0, 250), Vector2(15, 25))
	elif direction == 0:
		if is_attacking and Ebar.value > 0:
			match arma_actual:
				1:
					anim = "hit"
					sprite_scale = Vector2(facing * 0.9, 1.0)
					#anim = "hit2"
					#sprite_scale = Vector2(facing * 0.9, 1.0)
					#anim = "hit3"
					#sprite_scale = Vector2(facing * 1.5, 1.5)
					#anim = "hit4"
					#sprite_scale = Vector2(facing * 2.4, 2.4)
				2, 3:
					anim = "hit_baston"
					sprite_scale = Vector2(facing * 2, 2)
					#set_health_shape(Vector2(-200 * facing, 0), Vector2(15, 30))
		elif is_blocking and Ebar.value > 0:
			anim = "blocking"
			sprite_scale = Vector2(facing * 2.3, 2)
			health_shape.disabled = true
	else:
		anim = "run" if is_running and Ebar.value > 20 else "walk"
		sprite_scale = Vector2(facing * (2.2 if is_running else 1.6), 2.2 if is_running else 1.5)

	red_suite.play(anim)
	red_suite.position = sprite_pos
	red_suite.scale = sprite_scale
	collision.position = collision_pos
	collision.scale = collision_scale
	await red_suite.animation_finished

# -------------------- Actualizar daño --------------------
func _update_damage(a, w):
	var hit_data: Dictionary = {}

	match w:
		1:
			match a:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100),"rotation":0.75 * PI,"scale":Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 15, "offset": Vector2(350, -50),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				"hit": hit_data = {"damage": 20, "offset": Vector2(300, -200),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				"hit2": hit_data = {"damage": 20, "offset": Vector2(300, -200),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				"hit3": hit_data = {"damage": 20, "offset": Vector2(300, -200),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				"hit4": hit_data = {"damage": 20, "offset": Vector2(300, -200),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				_: hitboxC.damage = 20
		2:
			match a:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100),"rotation":0.75 * PI,"scale":Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 20, "offset": Vector2(350, -50),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				"hit_baston": hit_data = {"damage": 25, "offset": Vector2(250, -100),"rotation":0.4 * PI,"scale":Vector2(6, 25)}
				_: hitboxC.damage = 25
		3:
			match a:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100),"rotation":0.75 * PI,"scale":Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 7, "offset": Vector2(350, -50),"rotation":0.5 * PI,"scale":Vector2(6, 10)}
				"hit_baston": hit_data = {"damage": 10, "offset": Vector2(250, -100),"rotation":0.4 * PI,"scale":Vector2(6, 25)}
				_: hitboxC.damage = 15

	if hit_data:
		hitboxC.damage = hit_data["damage"]
		if Ebar.value > 0:
			var offset = hit_data["offset"]
			var rotation = hit_data["rotation"]
			var scale = hit_data["scale"]
			offset.x *= facing
			await activar_hitbox(offset,rotation,scale)
			quitar_energia(1, 1)
	
# -------------------- Utilidades --------------------

func quitar_energia(D_act_rel, cansancio):
	Egen += 1
	if Egen > 10:
		Egen = 0
	if Egen == 10 or D_act_rel:
		Ebar.value -= cansancio
	Ebar.value = max(Ebar.value, -15)

func _detectar_enojo() -> int:
	return 1 if Rbar.value == 100 else 0

func Enojado(senojo) -> void:
	if senojo == 1 or enojado == 1:
		Rdegen += 1
		if Rdegen > 10:
			Rdegen = 0
		if Rdegen == 10:
			Rbar.value -= 1
			Rbar.value = max(Rbar.value, 0)

		enojado = 1
		hitboxC.damage += 20

		if Rbar.value == 0:
			enojado = 0
			hitboxC.damage -= 20

func Enojarse(senojo):
	Rbar.value = min(Rbar.value + senojo, 100)

func on_damage_took(deltavida) -> void:
	Enojarse(deltavida)

func on_health_changed(nueva_vida):
	pass

func set_health_shape(pos: Vector2, scale: Vector2) -> void:
	health_shape.disabled = false
	health_shape.position = pos
	health_shape.scale = scale


func activar_hitbox(pos: Vector2,rot,scale: Vector2) -> void:
	hitbox.position = pos
	hitbox.rotation = rot * facing
	hitbox.scale = scale
	hitbox.disabled = false
	await get_tree().create_timer(0.1).timeout
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

func _start_combo_attack(step):
	is_attacking = true
	can_combo = false
	combo_step = step

	match step:
		1:
			anim = "hit"
		2:
			anim = "hit2"
		3:
			anim = "hit3"
		4:
			anim = "hit4"
		_:
			anim = "hit"
			combo_step = 1

	red_suite.play(anim)
	await red_suite.animation_finished

	is_attacking = false
	can_combo = true
	combo_timer.start(0.5)  # Tiempo para continuar el combo

func _on_combo_timer_timeout() -> void:
	can_combo = false
	combo_step = 0
