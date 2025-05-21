extends CharacterBody2D

@export var gravity := 1200
@export var velocidad := 130
@export var distancia_ataque := 45
@export var distancia_detectar := 300
@export var tiempo_cooldown: float = 1.5  # en segundos

var ladron: Node2D
var jugador: Node2D
var estado: String = "idle"
var mepegaron : int = 0
var memori : int = 0
var puede_atacar: bool = true

@onready var animacion = $AnimatedSprite2D

func iniciar_cooldown():
	await get_tree().create_timer(tiempo_cooldown).timeout
	puede_atacar = true

func _ready():
	$HitboxComponent/CollisionShape2D.disabled = true
	jugador = get_parent().get_node("Daredevil")
	ladron = get_parent().get_node("Ladron")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if memori == 0:
		if mepegaron == 0:
			var distancia = abs(jugador.position.x - ladron.position.x)
			
			# calculamos direccion SIEMPRE
			var direccion = sign(jugador.global_position.x - global_position.x)
			# Esto devuelve 1 si jugador está a la derecha, -1 si está a la izquierda
			print("Direccion: ", direccion,"Distancia: ", distancia)
			print("Velocity X: ", velocity.x)
			# Actualizamos la orientación del sprite
			if direccion != 0 and sign(direccion) != sign($AnimatedSprite2D.scale.x):
				$AnimatedSprite2D.scale.x *= -1


			# comportamiento según distancia
			if distancia <= distancia_ataque:
				if puede_atacar:
					puede_atacar = false
					animacion.play("attack")
					velocity.x = 0
					iniciar_cooldown()
				animacion.play("attack")
				velocity.x = 0
			elif distancia <= distancia_detectar:
				velocity.x = direccion * velocidad
				animacion.play("idle")
				#animacion.play("run")
			else:
				velocity.x = 0
				animacion.play("idle")
		elif mepegaron == 1: 
			$AnimatedSprite2D.play("take_damage")
			await get_tree().create_timer(0.2).timeout
			mepegaron = 0
	
	move_and_slide()	

func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health - 60

func _on_health_component_on_damage_took() -> void:
	mepegaron = 1

func _on_health_component_on_dead() -> void:
	memori = 1
