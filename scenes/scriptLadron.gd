extends CharacterBody2D

@export var gravity := 1200
@export var velocidad := 130
@export var distancia_ataque := 45
@export var distancia_detectar := 300
@export var tiempo_cooldown: float = 0.75

var ladron: Node2D
var jugador: Node2D
var estado: String = "idle"
var mepegaron := false
var memori := false
var nopuedopegar := false

@onready var animacion = $AnimatedSprite2D

func _ready():
	$HitboxComponent/CollisionShape2D.disabled = true
	jugador = get_parent().get_node("Daredevil")
	ladron = self

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if memori:
		animacion.play("idle")
		velocity.x = 0
		move_and_slide()
		return

	if mepegaron:
		recibir_danio()
		return

	var distancia = abs(jugador.position.x - ladron.position.x)
	var direccion = sign(jugador.global_position.x - global_position.x)

	# Girar sprite según dirección
	if direccion != 0 and sign(direccion) != sign($AnimatedSprite2D.scale.x):
		$AnimatedSprite2D.scale.x *= -1

	# Si está en rango de ataque y no hay cooldown
	if distancia <= distancia_ataque and not nopuedopegar:
		atacar(direccion)
	elif distancia <= distancia_detectar:
		velocity.x = direccion * velocidad
		animacion.play("run")
	else:
		velocity.x = 0
		animacion.play("idle")

	move_and_slide()

func recibir_danio():
	animacion.play("take_damage")
	velocity.x = 0
	mepegaron = false
	await get_tree().create_timer(0.5).timeout  # delay por recibir daño

func atacar(direccion):
	nopuedopegar = true
	velocity.x = 0
	animacion.play("attack")
	$HitboxComponent/CollisionShape2D.disabled = false
	$HitboxComponent/CollisionShape2D.position.x = 30 * direccion
	await get_tree().create_timer(0.5).timeout  # duración del hit activo
	$HitboxComponent/CollisionShape2D.disabled = true
	await get_tree().create_timer(tiempo_cooldown).timeout
	nopuedopegar = false

func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health

func _on_health_component_on_damage_took() -> void:
	mepegaron = true

func _on_health_component_on_dead() -> void:
	memori = true
