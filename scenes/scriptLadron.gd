extends CharacterBody2D

@export var gravity := 1200
@export var velocidad: float = 100.0
@export var distancia_ataque: float = 30.0
@export var distancia_detectar: float = 200.0

var jugador: Node2D
var estado: String = "idle"
var mepegaron : int = 0
var memori : int = 0

@onready var animacion = $AnimatedSprite2D

func _ready():
	$HitboxComponent/CollisionShape2D.disabled = true
	jugador = get_parent().get_node("Daredevil")

func _physics_process(_delta):
	if not is_on_floor():
		velocity.y += gravity * _delta
	
	if memori == 0:
		if mepegaron == 0:
			var distancia = global_position.distance_to(jugador.global_position)
			if distancia <= distancia_ataque:
				$AnimatedSprite2D.play("attack")
			elif distancia <= distancia_detectar:
				perseguir(_delta)
			else:
				estado = "idle"
				$AnimatedSprite2D.play("idle")
		elif mepegaron ==1 : 
			$AnimatedSprite2D.play("take_damage")
			await get_tree().create_timer(0.2).timeout
			mepegaron = 0
	# elif memori == 1 : 
		# $AnimatedSprite2D.play("morido")
		# await get_tree().create_timer(1).timeout
		# $HitboxComponent/CollisionShape2D.disabled = true
		# $HealthComponent/CollisionShape2D.disabled = true
		# eliminar entidad del nivel

func perseguir(_delta):
	estado = "perseguir"
	var direccion = (jugador.global_position - global_position).normalized()
	velocity = direccion * velocidad
	move_and_slide()
	$AnimatedSprite2D.play("idle") # Puedes cambiar a "run

func _on_health_component_on_health_changed(health: int) -> void:
	$TextureProgressBar.value = health

func _on_health_component_on_damage_took() -> void:
	mepegaron = 1

func _on_health_component_on_dead() -> void:
	memori = 1
