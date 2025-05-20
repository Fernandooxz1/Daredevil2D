extends CharacterBody2D

@export var velocidad: float = 100.0
@export var distancia_ataque: float = 30.0
@export var distancia_detectar: float = 200.0

var jugador: Node2D
var estado: String = "idle"

@onready var animacion = $AnimatedSprite2D

func _ready():
	jugador = get_parent().get_node("Daredevil")

func _physics_process(_delta):
	
	var distancia = global_position.distance_to(jugador.global_position)
	if distancia <= distancia_ataque:
		$AnimatedSprite2D.play("attack")
	elif distancia <= distancia_detectar:
		perseguir(_delta)
	else:
		estado = "idle"
		$AnimatedSprite2D.play("idle")

func perseguir(_delta):
	estado = "perseguir"
	var direccion = (jugador.global_position - global_position).normalized()
	velocity = direccion * velocidad
	move_and_slide()
	$AnimatedSprite2D.play("idle") # Puedes cambiar a "run
