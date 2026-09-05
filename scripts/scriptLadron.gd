extends CharacterBody2D

# Variables de configuracion
@export var gravity := 1200
@export var speed := 130
@export var attack_range := 50.0
@export var detection_range := 450.0
@export var comfortable_range := 65.0  # Distancia preferida antes de atacar
@export var charge_damage := 40  # Daño del ataque cargado (~30% hp del jugador)
@export var charge_windup := 0.5  # Tiempo de carga antes de embestir (modificable)

# Maquina de estados
enum State { IDLE, APPROACH, CIRCLE, ATTACK, RETREAT, COOLDOWN, CHARGE_WINDUP, CHARGE_RUSH }
var current_state: State = State.IDLE

# Estado
var is_dead := false
var can_attack := true
var is_attacking := false
var stun_timer := 0.0
var is_stunned := false
var stun_immunity := 0.0  # Inmunidad al stun para que no lo CC-lockeen

# Timers y comportamiento
var state_timer := 0.0
var cooldown_duration := 0.6
var circle_direction := 1
var attack_count := 0  # Para que ataque varias veces seguidas
var attacks_since_charge := 0  # Contador para decidir cuando cargar

# Referencias
@onready var player: Node2D = get_parent().get_node_or_null("Daredevil") if get_parent() else null
@onready var heart_drop_scene = preload("res://scenes/items/heart.tscn")
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var healthbox: CollisionShape2D = $HealthComponent/CollisionShape2D
@onready var collision_shape = $CollisionShape2D
@onready var direction = 1
@onready var alert_icon: Node2D = get_node_or_null("AlertIcon")

var _highlight_tween: Tween = null
var _alert_tween: Tween = null
var _flash_tween: Tween = null
var _enemy_mat: ShaderMaterial = null
var is_air_launched: bool = false
var _last_hit_frame: int = -1

func _ready():
	add_to_group("detectables")
	if animation and animation.material is ShaderMaterial:
		animation.material = animation.material.duplicate()
		_enemy_mat = animation.material as ShaderMaterial
	if not alert_icon:
		alert_icon = get_node_or_null("AlertIcon")
	if alert_icon:
		alert_icon.visible = false
	hitbox.disabled = true
	current_state = State.IDLE
	cooldown_duration = randf_range(0.4, 1.0)
	if has_node("HealthComponent"):
		$HealthComponent.on_hit_received.connect(_on_hit_received)

# Loop principal

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Actualizar silueta / realce segun el modo de Daredevil
	var in_combat: bool = (player.get("is_combat_stance") == true or player.get("is_radar_active") == true)
	if _enemy_mat and (_highlight_tween == null or not _highlight_tween.is_valid()):
		_enemy_mat.set_shader_parameter("radar_highlight", in_combat)

	direction = sign(player.position.x - position.x)
	var distance = abs(player.position.x - position.x)

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# Muerto
	if is_dead:
		_stop("dead")
		collision_shape.disabled = true
		call_deferred("queue_free")
		return

	# Reducir inmunidad al stun
	if stun_immunity > 0:
		stun_immunity -= delta

	# Aturdido (reaccion al daño)
	if is_stunned:
		_process_stun(delta)
		move_and_slide()
		return

	# Mirar al jugador
	_update_facing(direction)

	# Maquina de estados
	match current_state:
		State.IDLE:
			_state_idle(distance, delta)
		State.APPROACH:
			_state_approach(distance, delta)
		State.CIRCLE:
			_state_circle(distance, delta)
		State.ATTACK:
			_state_attack(distance, delta)
		State.RETREAT:
			_state_retreat(distance, delta)
		State.COOLDOWN:
			_state_cooldown(distance, delta)
		State.CHARGE_WINDUP:
			_state_charge_windup(distance, delta)
		State.CHARGE_RUSH:
			_state_charge_rush(distance, delta)

	move_and_slide()

# Estados

func _state_idle(distance: float, _delta: float):
	velocity.x = 0
	if animation.animation != "idle":
		animation.play("idle")

	# Detectar jugador
	if distance <= detection_range:
		current_state = State.APPROACH

func _state_approach(distance: float, _delta: float):
	# Si el jugador se fue muy lejos, volver a idle
	if distance > detection_range:
		current_state = State.IDLE
		velocity.x = 0
		return

	# Si esta cerca, decidir que hacer
	if distance <= comfortable_range:
		# Decidir: ataque normal, rodear, o ataque cargado
		var choice = randf()
		if attacks_since_charge >= 3 and choice < 0.5:
			# Despues de varios ataques, intentar carga especial
			current_state = State.CHARGE_WINDUP
			state_timer = charge_windup
			attacks_since_charge = 0
		elif choice < 0.70:
			current_state = State.ATTACK
			attack_count = randi_range(1, 3)
		else:
			current_state = State.CIRCLE
			circle_direction = 1 if randf() > 0.5 else -1
			state_timer = randf_range(0.3, 0.7)
		return

	# Caminar hacia el jugador (agresivo)
	velocity.x = direction * speed * 1.1
	if animation.animation != "idle":
		animation.play("idle")

func _state_circle(distance: float, delta: float):
	state_timer -= delta

	# Si el jugador se alejo, ir a buscarlo
	if distance > comfortable_range * 1.8:
		current_state = State.APPROACH
		return

	# Moverse de lado
	velocity.x = circle_direction * speed * 0.5

	if animation.animation != "idle":
		animation.play("idle")

	# Cuando termina el timer, atacar
	if state_timer <= 0:
		current_state = State.ATTACK
		attack_count = randi_range(1, 2)

func _state_attack(distance: float, _delta: float):
	if not can_attack or is_attacking:
		return

	# Si esta lejos, acercarse rapido (embestida)
	if distance > attack_range:
		velocity.x = direction * speed * 1.5
		if animation.animation != "idle":
			animation.play("idle")

		# Si esta demasiado lejos, volver a acercarse normalmente
		if distance > comfortable_range * 1.3:
			current_state = State.APPROACH
		return

	# En rango, pegar
	_perform_attack(direction)

func _state_retreat(distance: float, delta: float):
	state_timer -= delta

	# Alejarse del jugador
	velocity.x = -direction * speed * 0.8

	if animation.animation != "idle":
		animation.play("idle")

	# Dejar de retroceder cuando paso el tiempo o esta lejos
	if state_timer <= 0 or distance >= comfortable_range * 1.3:
		velocity.x = 0
		current_state = State.COOLDOWN
		cooldown_duration = randf_range(0.3, 0.9)
		state_timer = cooldown_duration

func _state_cooldown(distance: float, delta: float):
	state_timer -= delta
	velocity.x = 0

	if animation.animation != "idle":
		animation.play("idle")

	# Cuando termina el cooldown, volver a pelear
	if state_timer <= 0:
		can_attack = true
		if distance <= detection_range:
			# Chance de carga especial despues de varios ataques
			if attacks_since_charge >= 4 and randf() < 0.6:
				current_state = State.CHARGE_WINDUP
				state_timer = charge_windup
				attacks_since_charge = 0
			elif randf() < 0.7:
				current_state = State.APPROACH
			else:
				current_state = State.CIRCLE
				circle_direction = 1 if randf() > 0.5 else -1
				state_timer = randf_range(0.3, 0.6)
		else:
			current_state = State.IDLE

# Ataque cargado: preparacion (se agacha para cargar)

func _state_charge_windup(distance: float, delta: float):
	state_timer -= delta
	velocity.x = 0

	# Animacion de carga (usar take_damage como placeholder, se agacha)
	if animation.animation != "take_damage":
		animation.play("take_damage")

	# Si Daredevil esta en Modo Combate / Radar, mostrar advertencia telegrafiada
	var show_warning: bool = (player != null and (player.get("is_combat_stance") == true or player.get("is_radar_active") == true))
	_show_attack_warning(show_warning)

	# Cuando termina la carga, embestir
	if state_timer <= 0:
		_show_attack_warning(false)
		current_state = State.CHARGE_RUSH
		state_timer = 1.2  # Tiempo maximo de embestida antes de frenar

func _state_charge_rush(distance: float, delta: float):
	state_timer -= delta

	# Correr hacia el jugador a maxima velocidad
	velocity.x = direction * speed * 2.5

	if animation.animation != "idle":
		animation.play("idle")

	# Si llega al rango de ataque, golpe fuerte
	if distance <= attack_range:
		# Cambiar estado ANTES de atacar para que no se vuelva a llamar cada frame
		current_state = State.COOLDOWN
		state_timer = randf_range(0.6, 1.2)
		_perform_charge_attack(direction)
		return

	# Si paso mucho tiempo sin alcanzar, frenar
	if state_timer <= 0:
		velocity.x = 0
		current_state = State.COOLDOWN
		state_timer = randf_range(0.5, 1.0)

# Procesar aturdimiento

func _process_stun(delta: float):
	_show_attack_warning(false)
	stun_timer -= delta

	if is_air_launched:
		# En el aire desacelera levemente con fricción de aire
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		# Si toca el suelo cayendo (velocity.y >= 0), concluye el lanzamiento aéreo
		if is_on_floor() and velocity.y >= 0.0:
			is_air_launched = false
			velocity.x = 0.0
	else:
		# En el suelo desliza suavemente con fricción
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)

	if stun_timer <= 0.0 and not is_air_launched:
		is_stunned = false
		is_attacking = false
		can_attack = true
		stun_immunity = 0.2  # Breve ventana de protección post-combo
		# Despues de recibir golpe, retroceder un poco antes de volver
		current_state = State.RETREAT
		state_timer = randf_range(0.15, 0.3)

# Funciones auxiliares

func _stop(anim_name: String):
	if animation.animation != anim_name:
		animation.play(anim_name)
	velocity.x = 0

func _update_facing(dir: int):
	if dir != 0 and sign(dir) != sign(animation.scale.x):
		animation.scale.x *= -1

# Ataque normal

func _perform_attack(dir: int) -> void:
	if is_attacking or not can_attack:
		return

	is_attacking = true
	can_attack = false
	velocity.x = 0
	attacks_since_charge += 1

	animation.play("attack")
	hitbox.position.x = 30 * dir
	hitbox.disabled = false

	await get_tree().create_timer(0.1).timeout
	if is_stunned:
		_end_attack_early()
		return

	hitbox.disabled = true
	await animation.animation_finished
	if is_stunned:
		_end_attack_early()
		return

	is_attacking = false
	attack_count -= 1

	# Si todavia le quedan ataques en la rafaga, atacar de nuevo rapido
	if attack_count > 0:
		can_attack = true
		await get_tree().create_timer(randf_range(0.1, 0.25)).timeout
		if not is_stunned and attack_count > 0:
			current_state = State.ATTACK
			can_attack = true
			return

	# Si no, retroceder
	current_state = State.RETREAT
	state_timer = randf_range(0.15, 0.4)

# Ataque cargado (golpe fuerte despues de embestir)

func _perform_charge_attack(dir: int) -> void:
	is_attacking = true
	can_attack = false
	velocity.x = 0

	animation.play("attack")
	hitbox.position.x = 35 * dir
	hitbox.disabled = false

	# El daño cargado es mucho mayor
	$HitboxComponent.damage = charge_damage

	await get_tree().create_timer(0.15).timeout
	if is_stunned:
		_end_attack_early()
		return

	hitbox.disabled = true

	await animation.animation_finished
	if is_stunned:
		_end_attack_early()
		return

	# Restaurar daño normal
	$HitboxComponent.damage = 10

	is_attacking = false

	# Despues de carga, cooldown mas largo (queda expuesto)
	current_state = State.COOLDOWN
	state_timer = randf_range(0.6, 1.2)

func _end_attack_early():
	hitbox.disabled = true
	is_attacking = false
	can_attack = true
	$HitboxComponent.damage = 10  # Restaurar daño normal

# Eventos de vida

func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health

func _on_hit_received(hit_data: Dictionary) -> void:
	apply_hit_impact(hit_data)

func _on_health_component_on_damage_took(damage_amount) -> void:
	var hit_data = $HealthComponent.last_hit_data if has_node("HealthComponent") else {}
	apply_hit_impact(hit_data, damage_amount)

func apply_hit_impact(hit_data: Dictionary = {}, damage_amount: int = 0) -> void:
	if is_dead:
		return

	var current_frame = Engine.get_process_frames()
	if _last_hit_frame == current_frame:
		return
	_last_hit_frame = current_frame

	# Interrumpir acciones y estados del enemigo
	is_attacking = false
	if hitbox:
		hitbox.disabled = true
	_show_attack_warning(false)
	is_stunned = true
	stun_immunity = 0.0 # Permitir encadenar golpes de combo
	if animation:
		_stop("take_damage")

	# 4. Hit Flash en Enemigos: destello blanco puro durante 0.05s
	play_hit_flash(0.05)

	# Determinar dirección de retroceso opuesta al atacante
	var knockback_dir: float = -1.0
	if player and is_instance_valid(player):
		var diff = player.global_position.x - global_position.x
		if abs(diff) > 0.01:
			knockback_dir = -sign(diff)
		elif "facing" in player:
			knockback_dir = float(player.facing)
	else:
		knockback_dir = -float(direction if direction != 0 else 1)

	# 3. Física de Knockback Diferenciada
	var attack_type = str(hit_data.get("attack_type", ""))
	var combo_step = int(hit_data.get("combo_step", 1))

	match attack_type:
		"hit1", "hit2":
			# Golpes 1 y 2: micro-stagger horizontal (retroceso de 90px/s)
			velocity.x = knockback_dir * 90.0
			velocity.y = 0.0
			stun_timer = 0.18
			is_air_launched = false
		"hit3":
			# Golpe 3: stagger medio (180px/s)
			velocity.x = knockback_dir * 180.0
			velocity.y = 0.0
			stun_timer = 0.25
			is_air_launched = false
		"hit4":
			# Golpe 4 (Uppercut): lanzamiento aéreo elevando al ladrón para rematarlo!
			velocity = Vector2(knockback_dir * 260.0, -420.0)
			stun_timer = 0.70
			is_air_launched = true
		"kick":
			# Patada: empuje horizontal fuerte
			velocity.x = knockback_dir * 450.0
			velocity.y = 0.0
			stun_timer = 0.35
			is_air_launched = false
		"boo1", "boo2":
			velocity.x = knockback_dir * 120.0
			velocity.y = 0.0
			stun_timer = 0.20
			is_air_launched = false
		"boo3":
			velocity.x = knockback_dir * 380.0
			velocity.y = -180.0
			stun_timer = 0.45
			is_air_launched = false
		_:
			if combo_step == 4:
				velocity = Vector2(knockback_dir * 260.0, -420.0)
				stun_timer = 0.70
				is_air_launched = true
			elif combo_step == 3:
				velocity.x = knockback_dir * 180.0
				velocity.y = 0.0
				stun_timer = 0.25
				is_air_launched = false
			else:
				velocity.x = knockback_dir * 90.0
				velocity.y = 0.0
				stun_timer = 0.18
				is_air_launched = false

func play_hit_flash(duration: float = 0.05) -> void:
	if _enemy_mat:
		_enemy_mat.set_shader_parameter("hit_flash", 1.0)
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		if is_inside_tree():
			_flash_tween = create_tween()
			_flash_tween.tween_interval(duration)
			_flash_tween.tween_callback(func():
				if _enemy_mat:
					_enemy_mat.set_shader_parameter("hit_flash", 0.0)
			)
	elif animation:
		var orig_mod = animation.modulate
		animation.modulate = Color(5.0, 5.0, 5.0, 1.0)
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		if is_inside_tree():
			_flash_tween = create_tween()
			_flash_tween.tween_interval(duration)
			_flash_tween.tween_callback(func():
				if animation:
					animation.modulate = orig_mod
			)

func _on_health_component_on_dead() -> void:
	_show_attack_warning(false)
	is_dead = true
	play_hit_flash(0.05)
	if healthbox:
		healthbox.set_deferred("disabled", true)
	spawn_drop(heart_drop_scene, Vector2(0, -10))

# Crear drop al morir

func spawn_drop(scene, offset: Vector2):
	var instance = scene.instantiate()
	instance.global_position = global_position + offset
	get_parent().call_deferred("add_child", instance)

# ==============================================================================
# RADAR SENSE & TELEGRAPHING
# ==============================================================================

func on_radar_ping(origin: Vector2, radius: float) -> void:
	var dist = global_position.distance_to(origin)
	if dist <= radius:
		_highlight_silhouette(0.8)

func _highlight_silhouette(duration: float) -> void:
	if is_dead:
		return
	if _enemy_mat:
		_enemy_mat.set_shader_parameter("radar_highlight", true)
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()
	_highlight_tween = create_tween()
	animation.modulate = Color(2.4, 0.35, 0.35, 1.0)
	_highlight_tween.tween_property(animation, "modulate", Color(1.0, 1.0, 1.0, 1.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_highlight_tween.tween_callback(func():
		var in_combat: bool = player != null and (player.get("is_combat_stance") == true or player.get("is_radar_active") == true)
		if _enemy_mat:
			_enemy_mat.set_shader_parameter("radar_highlight", in_combat)
	)

func _show_attack_warning(show_it: bool) -> void:
	if not alert_icon or not is_instance_valid(alert_icon):
		alert_icon = get_node_or_null("AlertIcon")
	if not alert_icon:
		return

	if show_it and not is_dead:
		if not alert_icon.visible:
			alert_icon.visible = true
			alert_icon.scale = Vector2(0.2, 0.2)
			if _alert_tween and _alert_tween.is_valid():
				_alert_tween.kill()
			_alert_tween = create_tween()
			_alert_tween.tween_property(alert_icon, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_alert_tween.tween_property(alert_icon, "scale", Vector2(1.0, 1.0), 0.08)
	else:
		alert_icon.visible = false
