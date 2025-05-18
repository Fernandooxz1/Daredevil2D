class_name Daredevil
extends CharacterBody2D

@export var gravity := 1200
@export var jump_speed := 600
@export var speed := 200
@export var run_multiplier := 2.0
@export var acceleration := 1000
@export var friction := 4500

var facing := 1

func _physics_process(delta):
	var is_grounded := is_on_floor()
	var direction := Input.get_axis("left", "right")
	var is_running := Input.is_action_pressed("run")
	var is_attacking := Input.is_action_pressed("attack")
	var jump_pressed := Input.is_action_just_pressed("jump") and is_grounded
	var is_crouching := Input.is_action_pressed("crouch")

	# Aplicar gravedad
	if not is_grounded:
		velocity.y += gravity * delta

	# Saltar
	if jump_pressed:
		velocity.y = -jump_speed

	# Movimiento horizontal
	if is_crouching and is_grounded:
		# No permitir movimiento al estar agachado
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif direction != 0:
		facing = sign(direction)
		var target_speed = speed * (run_multiplier if is_running else 1)
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Animaciones
	_update_animation(is_grounded, direction, is_running, is_attacking, is_crouching)

	move_and_slide()

func _update_animation(is_grounded: bool, direction: float, is_running: bool, is_attacking: bool, is_crouching: bool) -> void:
	var anim = "idle"
	var Sscale_x = facing * 2.0
	var Sscale_y = 2.0
	var Sposition_x = 0
	var Sposition_y = 0
	var Cscale_x = 50.0
	var Cscale_y = 50.0
	var Cposition_x = 0
	var Cposition_y = 0
	

	if not is_grounded:
		if is_attacking:
			anim = "jump_hit"
			Sscale_x = facing * 0.975
			Sscale_y = 0.975
		else:
			anim = "jump"
			Sscale_x = facing * 0.975
			Sscale_y = 0.975
	elif is_crouching:
		if is_attacking:
			anim = "crouch_hit"
			Sscale_x = facing * 2.6
			Sscale_y = 2.5
			Sposition_x= facing * 50
			Sposition_y= 150
		else:
			anim = "crouch"
			Sscale_x = facing * 0.85
			Sscale_y = 0.8
			Sposition_x= 0
			Sposition_y= 150
	elif is_attacking and direction == 0:
		anim = "hit"
		Sscale_x = facing * 0.9
		Sscale_y = 1.0
	elif direction != 0:
		anim = "run" if is_running else "walk"
		Sscale_x = facing * (2.2 if is_running else 1.6)
		Sscale_y = 2.2 if is_running else 1.5
	
	$RedSuite.play(anim)
	$RedSuite.position = Vector2(Sposition_x, Sposition_y)
	$RedSuite.scale = Vector2(Sscale_x, Sscale_y)
	$CollisionDD.position = Vector2(Cposition_x,Cposition_x)
	$CollisionDD.scale = Vector2(Cscale_x,Cscale_y)
