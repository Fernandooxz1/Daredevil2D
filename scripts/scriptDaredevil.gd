
extends CharacterBody2D

signal actual_weapon

@export var gravity := 1200
@export var jump_speed := 600
@export var speed := 200
@export var run_multiplier := 2.0
@export var acceleration := 1000
@export var friction := 4500
var dead : int = 0
var semurio = 1
var arma_actual : int = 1 # (1 = puños, 2 = baston, 3 = duales)

func _ready() -> void:
	$HitboxComponent/HitShapeDD.disabled = true
	$HealthComponent/HealthShapeDD.disabled = false

func _on_dead()-> void:
	dead = 1 

var facing := 1

func _physics_process(delta):
	var is_grounded := is_on_floor()
	var direction := Input.get_axis("left", "right")
	var is_running := Input.is_action_pressed("run")
	var is_attacking := Input.is_action_pressed("attack")
	var jump_pressed := Input.is_action_just_pressed("jump") and is_grounded
	var is_crouching := Input.is_action_pressed("crouch")
	var is_blocking := Input.is_action_pressed("blokear")
	var change_weapon := Input.is_action_just_pressed("Cambiar Arma")

	# Aplicar gravedad
	if not is_grounded:
		velocity.y += gravity * delta
	
	if dead == 0:
		#cambiar arma
		if change_weapon:
			print(arma_actual)
			arma_actual = arma_actual + 1
			actual_weapon.emit(arma_actual)
			if arma_actual > 2:
				arma_actual = 0
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
	else :
		velocity.x = 0
	# Animaciones
	_update_animation(is_blocking,is_grounded, direction, is_running, is_attacking, is_crouching)
	move_and_slide()

func _update_animation(is_blocking,is_grounded: bool, direction: float, is_running: bool, is_attacking: bool, is_crouching: bool) -> void:
	
	$HealthComponent/HealthShapeDD.disabled = false
	
	var anim
	var Sscale_x = facing * 2.2
	var Sscale_y = 2.0
	var Sposition_x = 0
	var Sposition_y = 0
	var Cscale_x = 50.0
	var Cscale_y = 65.0
	var Cposition_x = 0
	var Cposition_y = 0
	
	# establesco el idle_inicial
	if arma_actual == 1:
		anim = "idle"
		$HealthComponent/HealthShapeDD.position.x = 0
		$HealthComponent/HealthShapeDD.position.y = 0
		$HealthComponent/HealthShapeDD.scale.x = 15
		$HealthComponent/HealthShapeDD.scale.y = 30
	elif arma_actual == 2:
		anim = "baston_idle"
		$HealthComponent/HealthShapeDD.position.x = -200 * facing
		$HealthComponent/HealthShapeDD.position.y = 0
		$HealthComponent/HealthShapeDD.scale.x = 15
		$HealthComponent/HealthShapeDD.scale.y = 30
	elif arma_actual == 3:
		anim = "idle" #anim = "idle_dual"
		$HealthComponent/HealthShapeDD.position.x = 0
		$HealthComponent/HealthShapeDD.position.y = 0
		$HealthComponent/HealthShapeDD.scale.x = 15
		$HealthComponent/HealthShapeDD.scale.y = 30
	else:
		anim = "idle"
	
	if dead == 0:
		if not is_grounded:
			if is_attacking : #and arma_actual == 1:
				anim = "jump_hit"
				Sscale_x = facing * 0.975
				Sscale_y = 0.975
			# elif is_attacking and arma_actual == 2:
				# anim = "jump_hit_Baston"
				# Sscale_x = facing * 0.975
				# Sscale_y = 0.975
			# elif is_attacking and arma_actual == 3:
				# anim = "jump_balance_Baston"
				# Sscale_x = facing * 0.975
				# Sscale_y = 0.975
				
			else:
				anim = "jump"
				Sscale_x = facing * 0.975
				Sscale_y = 0.975
				
		elif is_crouching:
			if is_attacking: # and arma_actual == 1:
				anim = "crouch_hit"
				Sscale_x = facing * 2.6
				Sscale_y = 2.5
				Sposition_x= facing * 50
				Sposition_y= 150
			# elif is_attacking and arma_actual == 2:
				# anim = "crouch_hit_Baston"
				# Sscale_x = facing * 0.975
				# Sscale_y = 0.975
			# elif is_attacking and arma_actual == 3:
				# anim = "crouch_hit_duales"
				# Sscale_x = facing * 0.975
				# Sscale_y = 0.975
				
				$HealthComponent/HealthShapeDD.position.y = 150
				$HealthComponent/HealthShapeDD.scale.y = 25
			else:
				anim = "crouch"
				Sscale_x = facing * 0.85
				Sscale_y = 0.8
				Sposition_x= 0
				Sposition_y= 150
				
				$HealthComponent/HealthShapeDD.position.y = 150
				$HealthComponent/HealthShapeDD.scale.y = 25
		elif direction == 0:
			if is_attacking and arma_actual == 1:
				anim = "hit"
				Sscale_x = facing * 0.9
				Sscale_y = 1.0
			elif is_attacking and arma_actual == 2:
				anim = "hit_baston"
				Sscale_x = facing * 2
				Sscale_y = 2
			# elif is_attacking and arma_actual == 3:
				# anim = "hit_duales"
				# Sscale_x = facing * 0.975
				# Sscale_y = 0.975
				
				$HealthComponent/HealthShapeDD.position.y = 0
				$HealthComponent/HealthShapeDD.scale.y = 30
			elif is_blocking:
				#anim = "blocking"
				anim = "idle"
				Sscale_x = facing * 2.3
				Sscale_y = 2
				$HealthComponent/HealthShapeDD.disabled = true
				$HealthComponent/HealthShapeDD.position.y = 0
				$HealthComponent/HealthShapeDD.scale.y = 30
				
				
		elif direction != 0:
			anim = "run" if is_running else "walk"
			Sscale_x = facing * (2.2 if is_running else 1.6)
			Sscale_y = 2.2 if is_running else 1.5
			
		$RedSuite.play(anim)
		$RedSuite.position = Vector2(Sposition_x, Sposition_y)
		$RedSuite.scale = Vector2(Sscale_x, Sscale_y)
		$CollisionDD.position = Vector2(Cposition_x,Cposition_x)
		$CollisionDD.scale = Vector2(Cscale_x,Cscale_y)
		
		if anim == "hit" :
			$HitboxComponent/HitShapeDD.position = Vector2(350 * facing,-200)
			$HitboxComponent/HitShapeDD.disabled = false
			await get_tree().create_timer(0.1).timeout
			$HitboxComponent/HitShapeDD.disabled = true
		elif anim == "hit_baston":
			$HitboxComponent/HitShapeDD.position = Vector2(475 * facing,-175)
			$HealthComponent/HealthShapeDD.position.y = 0
			$HealthComponent/HealthShapeDD.scale.y = 30
			$HitboxComponent/HitShapeDD.disabled = false
			await get_tree().create_timer(0.1).timeout
			$HitboxComponent/HitShapeDD.disabled = true
		elif anim == "crouch_hit":
			$HitboxComponent/HitShapeDD.position = Vector2(450 * facing,-100)
			$HealthComponent/HealthShapeDD.position.y = 150
			$HealthComponent/HealthShapeDD.scale.y = 25
			$HitboxComponent/HitShapeDD.disabled = false
			await get_tree().create_timer(0.1).timeout
			$HitboxComponent/HitShapeDD.disabled = true
		elif anim == "jump_hit":
			$HitboxComponent/HitShapeDD.position = Vector2(420 * facing,200)
			$HitboxComponent/HitShapeDD.disabled = false
			await get_tree().create_timer(0.1).timeout
			$HitboxComponent/HitShapeDD.disabled = true
	else:
		$RedSuite.position = Vector2(0,0)
		$RedSuite.scale = Vector2(2.3 * facing,2.3)
		$CollisionDD.position = Vector2(0,0)
		$CollisionDD.scale = Vector2(50,50)
		if semurio == 1:
			$RedSuite.play("dead")
			await $RedSuite.animation_finished
			if $RedSuite.animation == "dead":  # Verifica que terminó la animación correcta
				semurio = 0
		else:
			$RedSuite.play("morido")
			$RedSuite.scale = Vector2(2.5 * facing,2.5)
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_file("res://scenes/gameover.tscn")
