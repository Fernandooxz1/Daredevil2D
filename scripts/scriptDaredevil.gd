extends CharacterBody2D

signal weapon_changed

@export var gravity := 1200
@export var speed := 200

# Estado
var energy_regen_tick: int = 0
var energy_drain_tick: int = 0
var rage_decay_tick: int = 1
var is_rage_full: bool = false
var is_enraged: bool = false
var is_dead := false
var already_dead := false
var current_weapon: int = 1
var facing := 1
var punch_sound_toggle: bool = false
var is_kicking := false

# Flags de combate
var is_attacking := false
var combo_step := 0
var can_combo := false

# Movimiento
var jump_speed := 600
var acceleration := 1000
var friction := 4500
var run_multiplier := 2.0

# Referencias
@onready var combo_timer := $ComboTimer
@onready var red_suite = $RedSuite
@onready var hitbox_component = $HitboxComponent
@onready var hitbox = $HitboxComponent/HitShapeDD
@onready var health_shape = $HealthComponent/HealthShapeDD
@onready var health_comp = $HealthComponent
@onready var collision = $CollisionDD
@onready var energy_bar = $Camera2D2/HUD/EnergyBar
@onready var rage_bar = $Camera2D2/HUD/RageBar
@onready var heartbeat_sfx = $HeartbeatSFX
@onready var punch2_sfx = $Punch2SFX
@onready var punch3_sfx = $Punch3SFX
@onready var kick_sfx = $KickSFX
@onready var running_sfx = $RunningSFX
@onready var breathing_fast_sfx = $BreathingFastSFX
@onready var anim = "idle"

const GAME_OVER_SCENE_PATH := "res://scenes/gameover.tscn"

func _ready() -> void:
	hitbox.disabled = true
	health_shape.disabled = false
	rage_bar.value = 0
	energy_bar.value = 100
	health_comp.on_damage_took.connect(_on_damage_took)
	health_comp.on_health_changed.connect(_on_health_changed)
	heartbeat_sfx.finished.connect(_on_heartbeat_finished)
	breathing_fast_sfx.finished.connect(_on_breathing_fast_finished)

func _on_dead() -> void:
	is_dead = true

func _physics_process(delta):
	var is_grounded := is_on_floor()
	var direction := Input.get_axis("left", "right")
	var is_running := Input.is_action_pressed("run")
	var attack_pressed := Input.is_action_just_pressed("attack")
	var kick_pressed := Input.is_action_just_pressed("hability1")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var is_crouching := Input.is_action_pressed("crouch")
	var is_blocking := Input.is_action_pressed("blokear")
	var change_weapon := Input.is_action_just_pressed("Cambiar Arma")

	# Patada (F key)
	if kick_pressed and not is_attacking and not is_kicking and not is_running and energy_bar.value > 20:
		_perform_kick()

	# Rutina de combos (no permitir mientras corre)
	if attack_pressed and not (is_running and direction != 0):
		if !is_attacking:
			_start_combo_attack(1)
		elif can_combo:
			_start_combo_attack(combo_step + 1)

	# Regeneración de energía (cada 3 ticks recupera +2)
	energy_regen_tick += 1
	if energy_regen_tick >= 3:
		energy_regen_tick = 0
		energy_bar.value = min(energy_bar.value + 2, 100)

	if not is_grounded:
		velocity.y += gravity * delta

	if is_dead:
		_process_death()
		return

	if change_weapon:
		current_weapon = current_weapon % 3 + 1
		weapon_changed.emit(current_weapon)

	# Saltos (costo fijo al saltar, no drena en el aire)
	if jump_pressed and is_on_wall() and energy_bar.value > 0 and is_running and not is_grounded:
		velocity.x = 600 * -facing
		velocity.y = -jump_speed
		energy_bar.value = max(energy_bar.value - 5, 0)
	elif jump_pressed and is_grounded and energy_bar.value > 0:
		velocity.y = -jump_speed
		energy_bar.value = max(energy_bar.value - 5, 0)

	# Movimiento
	if is_crouching and is_grounded:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif direction != 0:
		facing = sign(direction)
		run_multiplier = 2.0 if energy_bar.value > 40 else 1.25
		var target_speed = speed * (run_multiplier if is_running and energy_bar.value > 20 else 0.75)
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		if target_speed == speed * run_multiplier:
			# Drenar energía al correr (cada 8 ticks gasta 1)
			drain_energy(1.0)
			# Sonido de correr (solo en el suelo)
			if is_grounded and not running_sfx.playing:
				running_sfx.play()
			elif not is_grounded and running_sfx.playing:
				running_sfx.stop()
		else:
			if running_sfx.playing:
				running_sfx.stop()
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if running_sfx.playing:
			running_sfx.stop()

	# Respiración agitada cuando la energía es baja
	if energy_bar.value <= 35:
		if not breathing_fast_sfx.playing:
			breathing_fast_sfx.play()
	else:
		if breathing_fast_sfx.playing:
			breathing_fast_sfx.stop()

	# Animaciones y estado (no sobreescribir durante patada)
	if not is_kicking:
		_update_animation(is_blocking, is_grounded, direction, is_running, is_attacking, is_crouching)
	_update_damage(anim, current_weapon)
	is_rage_full = check_rage_full()
	process_rage(is_rage_full)
	move_and_slide()

# --- Animación ---

func _update_animation(is_blocking, is_grounded: bool, direction: float, is_running: bool, attacking: bool, is_crouching: bool) -> void:
	self.anim = "idle"
	var sprite_scale = Vector2(facing * 2.2, 2.0)
	var sprite_pos = Vector2.ZERO
	var collision_scale = Vector2(50, 65)
	var collision_pos = Vector2.ZERO

	match current_weapon:
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
		anim = "jump_hit" if attacking and energy_bar.value > 0 else "jump"
		sprite_scale = Vector2(facing * 0.975, 0.975)
	elif is_crouching:
		anim = "crouch_hit" if attacking else "crouch"
		sprite_scale = Vector2(facing * (2.6 if attacking else 0.85), 2.5 if attacking else 0.8)
		sprite_pos = Vector2(facing * 50, 150) if attacking else Vector2(0, 150)
		set_health_shape(Vector2(0, 250), Vector2(15, 25))
	elif direction == 0:
		if attacking and energy_bar.value > 0:
			match current_weapon:
				1:
					anim = "hit"
					sprite_scale = Vector2(facing * 0.9, 1.0)
				2, 3:
					anim = "hit_baston"
					sprite_scale = Vector2(facing * 2, 2)
		elif is_blocking and energy_bar.value > 0:
			anim = "blocking"
			sprite_scale = Vector2(facing * 2.3, 2)
			health_shape.disabled = true
	else:
		anim = "run" if is_running and energy_bar.value > 20 else "walk"
		sprite_scale = Vector2(facing * (2.2 if is_running else 1.6), 2.2 if is_running else 1.5)
		

	red_suite.play(anim)
	red_suite.position = sprite_pos
	red_suite.scale = sprite_scale
	collision.position = collision_pos
	collision.scale = collision_scale
	await red_suite.animation_finished

# --- Daño ---

func _update_damage(anim_name, weapon_id):
	var hit_data: Dictionary = {}

	match weapon_id:
		1:
			match anim_name:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100), "rotation": 0.75 * PI, "scale": Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 15, "offset": Vector2(350, -50), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit": hit_data = {"damage": 20, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit2": hit_data = {"damage": 20, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit3": hit_data = {"damage": 20, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit4": hit_data = {"damage": 20, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"kick": hit_data = {"damage": 25, "offset": Vector2(350, -150), "rotation": 0.5 * PI, "scale": Vector2(8, 12)}
				_: hitbox_component.damage = 20
		2:
			match anim_name:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100), "rotation": 0.75 * PI, "scale": Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 20, "offset": Vector2(350, -50), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit_baston": hit_data = {"damage": 25, "offset": Vector2(250, -100), "rotation": 0.4 * PI, "scale": Vector2(6, 25)}
				_: hitbox_component.damage = 25
		3:
			match anim_name:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100), "rotation": 0.75 * PI, "scale": Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 7, "offset": Vector2(350, -50), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit_baston": hit_data = {"damage": 10, "offset": Vector2(250, -100), "rotation": 0.4 * PI, "scale": Vector2(6, 25)}
				_: hitbox_component.damage = 15

	if hit_data:
		hitbox_component.damage = hit_data["damage"]
		if energy_bar.value > 0:
			var offset = hit_data["offset"]
			var hit_rotation = hit_data["rotation"]
			var hit_scale = hit_data["scale"]
			offset.x *= facing
			await activate_hitbox(offset, hit_rotation, hit_scale)
			drain_energy(2.5)

# --- Utilidades ---

func drain_energy(amount: int):
	energy_bar.value = max(energy_bar.value - amount, 0)

func check_rage_full() -> bool:
	return rage_bar.value == 100

func process_rage(rage_full: bool) -> void:
	if rage_full or is_enraged:
		rage_decay_tick += 1
		if rage_decay_tick > 10:
			rage_decay_tick = 0
		if rage_decay_tick == 10:
			rage_bar.value -= 1
			rage_bar.value = max(rage_bar.value, 0)

		is_enraged = true
		hitbox_component.damage += 20

		if rage_bar.value == 0:
			is_enraged = false
			hitbox_component.damage -= 20

func add_rage(amount):
	rage_bar.value = min(rage_bar.value + amount, 100)

func _on_damage_took(damage_amount) -> void:
	add_rage(damage_amount)

func _on_health_changed(new_health):
	var threshold = health_comp.max_health * 0.10
	if new_health > 0 and new_health <= threshold:
		if not heartbeat_sfx.playing:
			heartbeat_sfx.play()
	else:
		if heartbeat_sfx.playing:
			heartbeat_sfx.stop()

func _on_heartbeat_finished():
	if health_comp.current_health > 0 and health_comp.current_health <= health_comp.max_health * 0.10:
		heartbeat_sfx.play()

func _on_breathing_fast_finished():
	if energy_bar.value <= 15:
		breathing_fast_sfx.play()

func set_health_shape(pos: Vector2, scale: Vector2) -> void:
	health_shape.disabled = false
	health_shape.position = pos
	health_shape.scale = scale

func activate_hitbox(pos: Vector2, rot, scale: Vector2) -> void:
	hitbox.position = pos
	hitbox.rotation = rot * facing
	hitbox.scale = scale
	hitbox.disabled = false
	await get_tree().create_timer(0.1).timeout
	hitbox.disabled = true

# --- Muerte ---

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

# --- Combos ---

func _start_combo_attack(step):
	is_attacking = true
	can_combo = false
	combo_step = step

	# Alternating punch sounds
	if punch_sound_toggle:
		punch2_sfx.play()
	else:
		punch3_sfx.play()
	punch_sound_toggle = !punch_sound_toggle

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
	combo_timer.start(0.5)

func _on_combo_timer_timeout() -> void:
	can_combo = false
	combo_step = 0

# --- Patada ---

func _perform_kick():
	is_kicking = true
	is_attacking = true
	kick_sfx.play()
	anim = "kick"
	red_suite.play("kick")
	red_suite.scale = Vector2(facing * 1.0, 1.0)

	# Activar hitbox de patada
	hitbox_component.damage = 35
	var offset = Vector2(350 * facing, -150)
	hitbox.position = offset
	hitbox.rotation = 0.5 * PI * facing
	hitbox.scale = Vector2(8, 12)
	hitbox.disabled = false
	await get_tree().create_timer(0.15).timeout
	hitbox.disabled = true

	# Drenar más energía que un golpe normal
	drain_energy(3.5)

	await red_suite.animation_finished
	is_kicking = false
	is_attacking = false
