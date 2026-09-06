extends CharacterBody2D

signal weapon_changed
signal radar_activated(duration: float)
signal radar_deactivated
signal radar_pulse(origin: Vector2, radius: float)
signal radar_cooldown_updated(remaining: float, total: float)
signal combat_stance_changed(is_combat: bool)

const RADAR_PULSE_INTERVAL: float = 1.25
const RADAR_DAMAGE_MULTIPLIER: float = 1.30
const RADAR_STAMINA_COST_REDUCTION: float = 0.75

# Sistema de Energía y Estamina (Fase 1)
const MAX_ENERGY: float = 100.0
const RECOVERY_DELAY_EXPLORATION: float = 0.8
const RECOVERY_DELAY_COMBAT: float = 1.2
const REGEN_RATE_EXPLORATION: float = 32.0
const REGEN_RATE_COMBAT: float = 24.0
const SPRINT_ENERGY_COST_PER_SEC: float = 18.2
const BLOCK_HOLD_ENERGY_COST_PER_SEC: float = 6.0
const EXHAUSTION_RECOVERY_THRESHOLD: float = 30.0

const BLOCK_SFX = preload("res://assets/Audio/blockedshield.mp3")

@export var gravity := 1200
@export var speed := 200

# Estado de Estamina & Bloqueo
var energy: float = 100.0
var stamina_recovery_timer: float = 0.0
var parry_window_timer: float = 0.0
var is_exhausted: bool = false
var is_guard_broken: bool = false
var guard_break_timer: float = 0.0
var block_sfx_player: AudioStreamPlayer = null

# Estado
var rage_decay_tick: int = 1
var is_rage_full: bool = false
var is_enraged: bool = false
var is_dead := false
var already_dead := false
var current_weapon: int = 1
var facing := 1
var is_kicking := false

# Cambio de Postura / Modo (Stance Switch)
var is_combat_stance: bool = false
var is_radar_active: bool = false # Sincronizado para retrocompatibilidad
var radar_pulse_timer: float = 0.0
var radar_overlay_rect: ColorRect = null
var radar_tween: Tween = null

# Combate
var is_attacking := false
var combo_step := 0
var can_combo := false

# Movimiento & Game Feel
var jump_speed := 600
var acceleration := 1000
var friction := 4500
var run_multiplier := 2.0

@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_in_air: bool = false

# Referencias
@onready var combo_timer = $ComboTimer if has_node("ComboTimer") else null
@onready var red_suite = $RedSuite if has_node("RedSuite") else null
@onready var hitbox_component = $HitboxComponent if has_node("HitboxComponent") else null
@onready var hitbox = $HitboxComponent/HitShapeDD if has_node("HitboxComponent/HitShapeDD") else null
@onready var health_shape = $HealthComponent/HealthShapeDD if has_node("HealthComponent/HealthShapeDD") else null
@onready var health_comp = $HealthComponent if has_node("HealthComponent") else null
@onready var collision = $CollisionDD if has_node("CollisionDD") else null
@onready var energy_bar = $Camera2D2/HUD/EnergyBar if has_node("Camera2D2/HUD/EnergyBar") else null
@onready var rage_bar = $Camera2D2/HUD/RageBar if has_node("Camera2D2/HUD/RageBar") else null
@onready var heartbeat_sfx = $HeartbeatSFX if has_node("HeartbeatSFX") else null
@onready var punch2_sfx = $Punch2SFX if has_node("Punch2SFX") else null
@onready var punch3_sfx = $Punch3SFX if has_node("Punch3SFX") else null
@onready var kick_sfx = $KickSFX if has_node("KickSFX") else null
@onready var running_sfx = $RunningSFX if has_node("RunningSFX") else null
@onready var breathing_fast_sfx = $BreathingFastSFX if has_node("BreathingFastSFX") else null
@onready var anim = "idle"

const GAME_OVER_SCENE_PATH := "res://scenes/gameover.tscn"

func _ready() -> void:
	add_to_group("player")
	if is_inside_tree():
		radar_overlay_rect = get_tree().get_first_node_in_group("radar_overlay")
	if hitbox:
		hitbox.disabled = true
	if health_shape:
		health_shape.disabled = false
	if rage_bar:
		rage_bar.value = 0
	energy = MAX_ENERGY
	if energy_bar:
		energy_bar.max_value = MAX_ENERGY
		energy_bar.value = energy
	if health_comp:
		health_comp.on_damage_took.connect(_on_damage_took)
		health_comp.on_health_changed.connect(_on_health_changed)
	if heartbeat_sfx:
		heartbeat_sfx.finished.connect(_on_heartbeat_finished)
	if breathing_fast_sfx:
		breathing_fast_sfx.finished.connect(_on_breathing_fast_finished)
	if hitbox_component:
		hitbox_component.on_hit_landed.connect(_on_hitbox_landed)

func _on_dead() -> void:
	is_dead = true
	if is_combat_stance:
		is_combat_stance = false
		is_radar_active = false
		_set_radar_overlay_active(false)
		radar_deactivated.emit()
		combat_stance_changed.emit(false)

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
	var toggle_stance_pressed := Input.is_action_just_pressed("poder1")

	# Actualizar temporizadores de estamina, parry y guard break
	var can_regen_stamina: bool = (stamina_recovery_timer <= 0.0)
	if stamina_recovery_timer > 0.0:
		stamina_recovery_timer = max(stamina_recovery_timer - delta, 0.0)
		can_regen_stamina = false
	if parry_window_timer > 0.0:
		parry_window_timer = max(parry_window_timer - delta, 0.0)
	if is_guard_broken:
		guard_break_timer -= delta
		if guard_break_timer <= 0.0:
			is_guard_broken = false

	# Abrir ventana de parry al presionar bloqueo
	if Input.is_action_just_pressed("blokear") and not is_guard_broken and energy > 0.0:
		parry_window_timer = 0.15

	# Drenaje continuo por mantener guardia
	if is_blocking and not is_guard_broken and energy > 0.0 and not is_attacking and not is_kicking:
		drain_energy(BLOCK_HOLD_ENERGY_COST_PER_SEC * delta)

	# Actualizar temporizadores de Coyote Time y Jump Buffer (Game Feel)
	if is_grounded:
		if was_in_air:
			was_in_air = false
			if is_inside_tree() and get_parent():
				DustPuff.spawn(get_parent(), global_position, Vector2(0, 54))
		coyote_timer = coyote_time
	else:
		was_in_air = true
		coyote_timer = max(coyote_timer - delta, 0.0)

	if jump_pressed:
		jump_buffer_timer = jump_buffer
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	# Procesar pulsos ritmicos en modo combate
	_process_radar_sense(delta)

	# Alternar entre Modo Exploración y Modo Combate (Stance Switch)
	if toggle_stance_pressed and not is_dead and not is_guard_broken:
		toggle_combat_stance()

	# Condición de sprint: solo en exploración, sin fatiga, con energía > 10.0 y sin guard break
	var can_sprint: bool = (not is_combat_stance) and (not is_exhausted) and is_running and energy > 10.0 and not is_guard_broken

	# Patada (cuesta 20.0 base, 15.0 con radar)
	if kick_pressed and not is_attacking and not is_kicking and not can_sprint and energy >= 20.0 and not is_guard_broken:
		_perform_kick()

	# Combos (no permitir mientras corre ni durante guard break)
	if attack_pressed and not (can_sprint and direction != 0) and energy >= 5.0 and not is_guard_broken:
		if can_combo and combo_step > 0:
			_start_combo_attack(combo_step + 1)
		elif !is_attacking:
			_start_combo_attack(1)

	# Regeneración pasiva continua con delta
	var is_currently_sprinting: bool = can_sprint and direction != 0 and is_running and is_grounded
	var is_actively_blocking: bool = is_blocking and not is_guard_broken and energy > 0.0
	if can_regen_stamina and not is_currently_sprinting and not is_actively_blocking and not is_guard_broken:
		var regen_rate = REGEN_RATE_COMBAT if is_combat_stance else REGEN_RATE_EXPLORATION
		energy = min(energy + regen_rate * delta, MAX_ENERGY)
		if energy_bar:
			energy_bar.value = energy

	if not is_grounded:
		velocity.y += gravity * delta

	if is_dead:
		_process_death()
		return

	if change_weapon and not is_guard_broken:
		current_weapon = current_weapon % 3 + 1
		weapon_changed.emit(current_weapon)

	# Saltos (con Coyote Time y Jump Buffering de 120ms)
	if jump_pressed and is_on_wall() and (not is_exhausted) and energy >= 12.0 and can_sprint and not is_grounded and not is_guard_broken:
		# Wall Jump (12.0 estamina)
		velocity.x = 600 * -facing
		velocity.y = -jump_speed
		drain_energy(12.0)
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		if is_inside_tree() and get_parent():
			DustPuff.spawn(get_parent(), global_position, Vector2(0, 54))
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0 and energy >= 6.0 and not is_guard_broken:
		# Salto de piso (6.0 estamina)
		velocity.y = -jump_speed
		drain_energy(6.0)
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		if is_inside_tree() and get_parent():
			DustPuff.spawn(get_parent(), global_position, Vector2(0, 54))

	# Movimiento y Tradeoff de Postura
	if is_guard_broken:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if running_sfx and running_sfx.playing:
			running_sfx.stop()
	elif is_crouching and is_grounded:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if running_sfx and running_sfx.playing:
			running_sfx.stop()
	elif direction != 0:
		facing = sign(direction)
		var target_speed: float = 0.0
		var is_sprinting: bool = false

		if is_combat_stance:
			# Modo Combate / Radar Stance: Postura de guardia/boxeo calculada. NO puede correr.
			target_speed = speed * 0.8
		else:
			# Modo Exploración
			if is_exhausted:
				target_speed = speed * 0.70
			elif can_sprint:
				run_multiplier = 2.0 if energy > 40.0 else 1.25
				target_speed = speed * run_multiplier
				is_sprinting = true
			else:
				target_speed = speed * 1.0

		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)

		if is_sprinting:
			# Drenar energia al correr continuo
			drain_energy(SPRINT_ENERGY_COST_PER_SEC * delta)
			# Sonido de correr (solo en el suelo)
			if is_grounded and running_sfx and not running_sfx.playing:
				running_sfx.play()
			elif not is_grounded and running_sfx and running_sfx.playing:
				running_sfx.stop()
		else:
			if running_sfx and running_sfx.playing:
				running_sfx.stop()
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if running_sfx and running_sfx.playing:
			running_sfx.stop()

	# Manejo de fatiga y respiración agitada
	if is_exhausted and energy >= EXHAUSTION_RECOVERY_THRESHOLD:
		is_exhausted = false
	if is_exhausted and breathing_fast_sfx and not breathing_fast_sfx.playing:
		breathing_fast_sfx.play()
	elif not is_exhausted and energy > 35.0 and breathing_fast_sfx and breathing_fast_sfx.playing:
		breathing_fast_sfx.stop()

	# Animaciones (no sobreescribir durante patada ni combos)
	if not is_kicking and not is_attacking:
		var active_running: bool = can_sprint and direction != 0
		_update_animation(is_blocking, is_grounded, direction, active_running, is_attacking, is_crouching)
		_update_damage(anim, current_weapon)
	is_rage_full = check_rage_full()
	process_rage(is_rage_full)
	move_and_slide()

# Animacion

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

	# Animaciones segun el estado
	if not is_grounded:
		anim = "jump_hit" if attacking and energy > 0 else "jump"
		sprite_scale = Vector2(facing * 0.975, 0.975)
	elif is_crouching:
		anim = "crouch_hit" if attacking else "crouch"
		sprite_scale = Vector2(facing * (2.6 if attacking else 0.85), 2.5 if attacking else 0.8)
		sprite_pos = Vector2(facing * 50, 150) if attacking else Vector2(0, 150)
		set_health_shape(Vector2(0, 250), Vector2(15, 25))
	elif direction == 0:
		if attacking and energy > 0:
			match current_weapon:
				1:
					anim = "hit"
					sprite_scale = Vector2(facing * 0.9, 1.0)
				2, 3:
					anim = "hit_baston"
					sprite_scale = Vector2(facing * 2, 2)
		elif is_blocking and energy > 0.0 and not is_guard_broken:
			anim = "blocking"
			sprite_scale = Vector2(facing * 2.3, 2)
			health_shape.disabled = false
	else:
		anim = "run" if is_running and energy > 10.0 and not is_exhausted else "walk"
		sprite_scale = Vector2(facing * (2.2 if is_running else 1.6), 2.2 if is_running else 1.5)
		

	red_suite.play(anim)
	red_suite.position = sprite_pos
	red_suite.scale = sprite_scale
	collision.position = collision_pos
	collision.scale = collision_scale

# Daño (solo corre cuando NO esta en combo ni patada)

func _update_damage(anim_name, weapon_id):
	var hit_data: Dictionary = {}

	match weapon_id:
		1:
			match anim_name:
				"jump_hit": hit_data = {"damage": 25, "offset": Vector2(280, 100), "rotation": 0.75 * PI, "scale": Vector2(10, 15)}
				"crouch_hit": hit_data = {"damage": 15, "offset": Vector2(350, -50), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit": hit_data = {"damage": 20, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit2": hit_data = {"damage": 20, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit3": hit_data = {"damage": 25, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(6, 10)}
				"hit4": hit_data = {"damage": 35, "offset": Vector2(300, -200), "rotation": 0.5 * PI, "scale": Vector2(7, 11)}
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
		hitbox_component.attack_type = anim_name
		hitbox_component.attacker = self
		hitbox_component.hit_stop_duration = 0.08 if (anim_name == "hit4" or anim_name == "kick") else 0.04
		hitbox_component.trauma_amount = 0.45 if (anim_name == "hit4" or anim_name == "kick") else 0.15
		if energy > 0:
			var offset = hit_data["offset"]
			var hit_rotation = hit_data["rotation"]
			var hit_scale = hit_data["scale"]
			offset.x *= facing
			await activate_hitbox(offset, hit_rotation, hit_scale)

# Utilidades

func drain_energy(amount: float) -> void:
	energy = max(energy - amount, 0.0)
	if energy_bar:
		energy_bar.value = energy
	stamina_recovery_timer = RECOVERY_DELAY_COMBAT if is_combat_stance else RECOVERY_DELAY_EXPLORATION
	if energy <= 0.0:
		is_exhausted = true

func refund_energy(amount: float) -> void:
	energy = min(energy + amount, MAX_ENERGY)
	if energy_bar:
		energy_bar.value = energy
	if is_exhausted and energy >= EXHAUSTION_RECOVERY_THRESHOLD:
		is_exhausted = false

func _play_block_sfx(pitch: float = 1.0) -> void:
	if not block_sfx_player:
		block_sfx_player = AudioStreamPlayer.new()
		block_sfx_player.name = "BlockSFXPlayer"
		block_sfx_player.stream = BLOCK_SFX
		block_sfx_player.volume_db = -4.0
		add_child(block_sfx_player)
	block_sfx_player.pitch_scale = pitch
	block_sfx_player.play()

func trigger_guard_break() -> void:
	is_guard_broken = true
	guard_break_timer = 0.8
	is_exhausted = true
	is_attacking = false
	is_kicking = false
	can_combo = false
	velocity.x = -facing * 180.0
	var tree = get_tree()
	if tree:
		HitStopHelper.freeze(tree, 0.10)
	CameraDaredevil.shake(0.35)
	_play_block_sfx(0.60)
	if punch3_sfx:
		punch3_sfx.play()
	var hud = get_node_or_null("Camera2D2/HUD")
	if hud and hud.has_method("trigger_insufficient_energy_feedback"):
		hud.trigger_insufficient_energy_feedback()

func intercept_damage(incoming_damage: int, hit_data: Dictionary = {}) -> int:
	var is_blocking: bool = Input.is_action_pressed("blokear")
	if is_blocking and not is_guard_broken and energy > 0.0 and not is_dead:
		if parry_window_timer > 0.0:
			# Parry Perfecto: Frame-tight (primeros 0.15s)
			refund_energy(25.0)
			add_rage(10.0)
			_play_block_sfx(1.35)
			var tree = get_tree()
			if tree:
				HitStopHelper.freeze(tree, 0.08)
			CameraDaredevil.shake(0.20)
			var attacker_node = hit_data.get("attacker")
			if attacker_node and is_instance_valid(attacker_node):
				if attacker_node.has_method("apply_hit_impact"):
					attacker_node.apply_hit_impact({"attack_type": "hit3", "combo_step": 2})
				if attacker_node.get("is_stunned") != null:
					attacker_node.is_stunned = true
					attacker_node.stun_timer = 0.85
			return 0
		else:
			# Bloqueo Regular
			var stamina_cost: float = max(float(incoming_damage) * 0.8, 12.0)
			if energy >= stamina_cost:
				drain_energy(stamina_cost)
				_play_block_sfx(1.0)
				var tree = get_tree()
				if tree:
					HitStopHelper.freeze(tree, 0.03)
				CameraDaredevil.shake(0.08)
				return 0
			else:
				# Guard Break: estamina insuficiente para absorber el impacto
				drain_energy(energy)
				trigger_guard_break()
				return int(float(incoming_damage) * 0.25)
	return incoming_damage

func _on_hitbox_landed(target_area: HealthComponent, hit_data: Dictionary) -> void:
	if target_area != health_comp:
		var attack_type = str(hit_data.get("attack_type", ""))
		if attack_type == "hit4" or hit_data.get("combo_step") == 4:
			refund_energy(15.0)

func check_rage_full() -> bool:
	return rage_bar != null and rage_bar.value == 100

func process_rage(rage_full: bool) -> void:
	if rage_full or is_enraged:
		rage_decay_tick += 1
		if rage_decay_tick > 10:
			rage_decay_tick = 0
		if rage_decay_tick == 10:
			if rage_bar:
				rage_bar.value -= 1
				rage_bar.value = max(rage_bar.value, 0)

		is_enraged = true
		hitbox_component.damage += 20

		if rage_bar and rage_bar.value == 0:
			is_enraged = false
			hitbox_component.damage -= 20

func add_rage(amount):
	if rage_bar:
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
	if is_exhausted or energy <= 15.0:
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

# Muerte

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

# Combos

func _start_combo_attack(step):
	# Elegir combo segun el arma equipada
	match current_weapon:
		1:
			_start_fist_combo(step)
		2:
			_start_boo_combo(step)
		3:
			_start_fist_combo(step)

# Combo puños (arma 1), 4 golpes

func _start_fist_combo(step):
	is_attacking = true
	can_combo = false
	if combo_timer:
		combo_timer.stop()  # Cancelar timer de combo anterior para que no resetee combo_step
	combo_step = step

	# Configuracion por paso (cambiar sprite_scale para ajustar cada golpe)
	var hit_anim := "hit"
	var sprite_scale := Vector2(facing * 0.9, 1.0)
	var hit_damage := 5
	var hit_offset := Vector2(300, -200)
	var hit_rotation := 0.5 * PI
	var hit_scale := Vector2(6, 10)
	var energy_cost := 5.0
	var hit_type := "hit1"
	var hit_stop_dur := 0.04
	var hit_trauma := 0.12

	match step:
		1:
			hit_anim = "hit"
			sprite_scale = Vector2(facing * 0.9, 1.0)  # <-- Ajustar escala hit1
			hit_damage = 5
			hit_type = "hit1"
			hit_stop_dur = 0.04
			hit_trauma = 0.12
			if punch2_sfx:
				punch2_sfx.play()
			print("hit1")
		2:
			hit_anim = "hit2"
			sprite_scale = Vector2(facing * 2.0, 2.0)  # <-- Ajustar escala hit2
			hit_damage = 5
			hit_type = "hit2"
			hit_stop_dur = 0.04
			hit_trauma = 0.15
			if punch3_sfx:
				punch3_sfx.play()
			print("hit2")
		3:
			hit_anim = "hit3"
			sprite_scale = Vector2(facing * 0.9, 1.0)  # <-- Ajustar escala hit3
			hit_damage = 10
			hit_type = "hit3"
			hit_stop_dur = 0.04
			hit_trauma = 0.22
			if punch2_sfx:
				punch2_sfx.play()
			print("hit3")
		4:
			hit_anim = "hit4"
			sprite_scale = Vector2(facing * 3.0, 2.5)  # <-- Ajustar escala hit4 (uppercut)
			hit_damage = 15
			hit_type = "hit4"
			hit_stop_dur = 0.08  # Micro-pausa prolongada en uppercut
			hit_trauma = 0.45    # Sacudida contundente
			hit_offset = Vector2(300, -200)
			hit_scale = Vector2(7, 11)
			energy_cost = 8.0
			if punch3_sfx:
				punch3_sfx.play()
			print("hit4")
		_:
			combo_step = 1
			if punch2_sfx:
				punch2_sfx.play()

	anim = hit_anim
	var current_stamina_ratio = RADAR_STAMINA_COST_REDUCTION if is_radar_active else 1.0
	drain_energy(energy_cost * current_stamina_ratio)

	if is_radar_active:
		add_rage(5.0)

	# Reproducir animacion con la escala del paso actual
	red_suite.play(hit_anim)
	red_suite.scale = sprite_scale
	red_suite.position = Vector2.ZERO

	# Activar hitbox una sola vez con los parámetros de impacto
	var current_multiplier = RADAR_DAMAGE_MULTIPLIER if is_radar_active else 1.0
	hitbox_component.damage = int(hit_damage * current_multiplier)
	hitbox_component.attack_type = hit_type
	hitbox_component.combo_step = step
	hitbox_component.hit_stop_duration = hit_stop_dur
	hitbox_component.trauma_amount = hit_trauma
	hitbox_component.attacker = self

	var offset = hit_offset
	offset.x *= facing
	hitbox.position = offset
	hitbox.rotation = hit_rotation * facing
	hitbox.scale = hit_scale
	hitbox.disabled = false

	# Esperar duracion de la animacion
	var anim_duration = _get_anim_duration(hit_anim)
	await get_tree().create_timer(max(anim_duration * 0.3, 0.05)).timeout
	hitbox.disabled = true
	await get_tree().create_timer(max(anim_duration * 0.7, 0.05)).timeout

	is_attacking = false

	# Despues del ultimo golpe (hit4) el combo termina, el proximo ataque empieza de cero
	if combo_step >= 4:
		can_combo = false
		combo_step = 0
	else:
		can_combo = true
		if combo_timer:
			combo_timer.start(0.5)

# Combo baston / Boo (arma 2), 3 golpes

func _start_boo_combo(step):
	is_attacking = true
	can_combo = false
	if combo_timer:
		combo_timer.stop()  # Cancelar timer de combo anterior para que no resetee combo_step

	# El boo solo tiene 3 golpes, si llega a mas reinicia
	if step > 3:
		step = 1
	combo_step = step

	# Configuracion por paso (cambiar sprite_scale para ajustar cada golpe)
	var hit_anim := "boo_hit1"
	var sprite_scale := Vector2(facing * 2.0, 2.0)
	var hit_damage := 15
	var hit_offset := Vector2(250, -100)
	var hit_rotation := 0.4 * PI
	var hit_scale := Vector2(6, 25)
	var energy_cost := 8.0
	var expose_after := false  # Solo el golpe 3 deja expuesto
	var hit_type := "boo1"
	var hit_stop_dur := 0.04
	var hit_trauma := 0.15

	match step:
		1:
			hit_anim = "boo_hit1"
			sprite_scale = Vector2(facing * 2.0, 2.0)  # <-- Ajustar escala boo_hit1
			hit_damage = 15
			hit_type = "boo1"
			hit_stop_dur = 0.04
			hit_trauma = 0.15
			energy_cost = 8.0
			punch2_sfx.play()  # Placeholder, cambiar por sfx del boo
			print("boo_hit1")
		2:
			hit_anim = "boo_hit2"
			sprite_scale = Vector2(facing * 2.0, 2.0)  # <-- Ajustar escala boo_hit2
			hit_damage = 15
			hit_type = "boo2"
			hit_stop_dur = 0.04
			hit_trauma = 0.18
			energy_cost = 8.0
			punch3_sfx.play()  # Placeholder, cambiar por sfx del boo
			print("boo_hit2")
		3:
			hit_anim = "boo_hit3"
			sprite_scale = Vector2(facing * 2.0, 2.0)  # <-- Ajustar escala boo_hit3 (golpe fuerte)
			hit_damage = 30
			hit_type = "boo3"
			hit_stop_dur = 0.08
			hit_trauma = 0.45
			hit_offset = Vector2(300, -100)
			hit_scale = Vector2(8, 28)
			energy_cost = 15.0
			expose_after = true  # Queda vulnerable 0.2s despues del golpe
			punch3_sfx.play()  # Placeholder, cambiar por sfx del golpe fuerte
			print("boo_hit3")
		_:
			combo_step = 1
			punch2_sfx.play()

	anim = hit_anim
	var current_stamina_ratio = RADAR_STAMINA_COST_REDUCTION if is_radar_active else 1.0
	drain_energy(energy_cost * current_stamina_ratio)

	if is_radar_active:
		add_rage(5.0)

	# Reproducir animacion con la escala del paso actual
	red_suite.play(hit_anim)
	red_suite.scale = sprite_scale
	red_suite.position = Vector2.ZERO

	# Activar hitbox una sola vez con los parámetros de combate
	var current_multiplier = RADAR_DAMAGE_MULTIPLIER if is_radar_active else 1.0
	hitbox_component.damage = int(hit_damage * current_multiplier)
	hitbox_component.attack_type = hit_type
	hitbox_component.combo_step = step
	hitbox_component.hit_stop_duration = hit_stop_dur
	hitbox_component.trauma_amount = hit_trauma
	hitbox_component.attacker = self

	var offset = hit_offset
	offset.x *= facing
	hitbox.position = offset
	hitbox.rotation = hit_rotation * facing
	hitbox.scale = hit_scale
	hitbox.disabled = false

	# Esperar duracion de la animacion
	var anim_duration = _get_anim_duration(hit_anim)
	await get_tree().create_timer(max(anim_duration * 0.3, 0.05)).timeout
	hitbox.disabled = true
	await get_tree().create_timer(max(anim_duration * 0.7, 0.05)).timeout

	# Ventana de exposicion despues del golpe 3 (no puede actuar)
	if expose_after:
		print("boo_exposed!")
		await get_tree().create_timer(0.2).timeout

	is_attacking = false

	# Despues del ultimo golpe (hit3) el combo termina, el proximo ataque empieza de cero
	if combo_step >= 3:
		can_combo = false
		combo_step = 0
	else:
		can_combo = true
		if combo_timer:
			combo_timer.start(0.5)

func _on_combo_timer_timeout() -> void:
	can_combo = false
	combo_step = 0

# Patada

func _perform_kick():
	is_kicking = true
	is_attacking = true
	if kick_sfx:
		kick_sfx.play()
	anim = "kick"
	red_suite.play("kick")
	red_suite.scale = Vector2(facing * 1.0, 1.0)

	# Hitbox de la patada (Game Feel: 0.08s freeze frame y trauma shake potente)
	var current_multiplier = RADAR_DAMAGE_MULTIPLIER if is_radar_active else 1.0
	hitbox_component.damage = int(15 * current_multiplier)
	hitbox_component.attack_type = "kick"
	hitbox_component.combo_step = 1
	hitbox_component.hit_stop_duration = 0.08
	hitbox_component.trauma_amount = 0.40
	hitbox_component.attacker = self

	var offset = Vector2(350 * facing, -150)
	hitbox.position = offset
	hitbox.rotation = 0.5 * PI * facing
	hitbox.scale = Vector2(8, 12)
	hitbox.disabled = false

	# Drenar energia de la patada
	var current_stamina_ratio = RADAR_STAMINA_COST_REDUCTION if is_radar_active else 1.0
	drain_energy(20.0 * current_stamina_ratio)

	if is_radar_active:
		add_rage(5.0)

	# Esperar duracion de la animacion
	var kick_duration = _get_anim_duration("kick")
	await get_tree().create_timer(max(kick_duration * 0.3, 0.05)).timeout
	hitbox.disabled = true
	await get_tree().create_timer(max(kick_duration * 0.7, 0.05)).timeout
	is_kicking = false
	is_attacking = false

func perform_hit_stop(duration: float = 0.04) -> void:
	HitStopHelper.freeze(get_tree(), duration)

# Calcular duracion real de una animacion a partir de sus frames

func _get_anim_duration(anim_name: String) -> float:
	var frames = red_suite.sprite_frames
	var count = frames.get_frame_count(anim_name)
	var speed = frames.get_animation_speed(anim_name)
	if speed <= 0 or count <= 0:
		return 0.4
	var total := 0.0
	for i in range(count):
		total += frames.get_frame_duration(anim_name, i)
	return total / speed


# ==============================================================================
# CAMBIO DE POSTURA / MODO COMBATE (STANCE SWITCH)
# ==============================================================================

func toggle_combat_stance() -> void:
	if is_dead:
		return

	is_combat_stance = !is_combat_stance
	is_radar_active = is_combat_stance
	radar_pulse_timer = 0.0

	_set_radar_overlay_active(is_combat_stance)

	if is_combat_stance:
		radar_activated.emit(0.0)
		combat_stance_changed.emit(true)
		_emit_radar_pulse()
	else:
		radar_deactivated.emit()
		combat_stance_changed.emit(false)

func try_activate_radar_sense() -> void:
	toggle_combat_stance()

func _process_radar_sense(delta: float) -> void:
	if is_combat_stance:
		radar_pulse_timer -= delta
		if radar_pulse_timer <= 0.0:
			radar_pulse_timer = RADAR_PULSE_INTERVAL
			_emit_radar_pulse()

func _emit_radar_pulse() -> void:
	radar_pulse.emit(global_position, 850.0)
	if heartbeat_sfx:
		heartbeat_sfx.play()
	if is_inside_tree():
		get_tree().call_group("detectables", "on_radar_ping", global_position, 850.0)

func _set_radar_overlay_active(active: bool) -> void:
	if not radar_overlay_rect or not is_instance_valid(radar_overlay_rect):
		if is_inside_tree():
			radar_overlay_rect = get_tree().get_first_node_in_group("radar_overlay")
	if not radar_overlay_rect or not radar_overlay_rect.material is ShaderMaterial:
		return

	var mat = radar_overlay_rect.material as ShaderMaterial
	if radar_tween and radar_tween.is_valid():
		radar_tween.kill()
	radar_tween = create_tween()

	if active:
		mat.set_shader_parameter("is_active", true)
		var current_intensity = mat.get_shader_parameter("intensity")
		var start_val: float = float(current_intensity) if current_intensity != null else 0.0
		radar_tween.tween_method(func(val: float): mat.set_shader_parameter("intensity", val), start_val, 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		var current_intensity = mat.get_shader_parameter("intensity")
		var start_val: float = float(current_intensity) if current_intensity != null else 0.0
		radar_tween.tween_method(func(val: float): mat.set_shader_parameter("intensity", val), start_val, 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		radar_tween.tween_callback(func(): mat.set_shader_parameter("is_active", false))
