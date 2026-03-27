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
@onready var player: Node2D = get_parent().get_node("Daredevil")
@onready var heart_drop_scene = preload("res://scenes/items/heart.tscn")
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var healthbox: CollisionShape2D = $HealthComponent/CollisionShape2D
@onready var collision_shape = $CollisionShape2D
@onready var direction = 1

func _ready():
	hitbox.disabled = true
	current_state = State.IDLE
	cooldown_duration = randf_range(0.4, 1.0)

# Loop principal

func _physics_process(delta):
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

	# Si lo golpean durante la carga, se cancela (ya manejado por is_stunned)

	# Cuando termina la carga, embestir
	if state_timer <= 0:
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
	stun_timer -= delta
	if stun_timer <= 0.15:
		velocity.x = 0
	if stun_timer <= 0:
		is_stunned = false
		is_attacking = false
		can_attack = true
		stun_immunity = 0.6  # 0.6 segundos sin poder ser aturdido de nuevo
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

func _on_health_component_on_damage_took(damage_amount) -> void:
	if is_stunned or stun_immunity > 0:
		return
	is_stunned = true
	_stop("take_damage")
	velocity.x = -sign(direction) * 100
	stun_timer = clamp(damage_amount * 0.015, 0.08, 0.3)

func _on_health_component_on_dead() -> void:
	is_dead = true
	healthbox.set_deferred("disabled", true)
	spawn_drop(heart_drop_scene, Vector2(0, -10))

# Crear drop al morir

func spawn_drop(scene, offset: Vector2):
	var instance = scene.instantiate()
	instance.global_position = global_position + offset
	get_parent().call_deferred("add_child", instance)
