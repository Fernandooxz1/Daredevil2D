class_name daredevil
extends CharacterBody2D

@export var gravity=1200
@export var jumpspeed=600
@export var velocidad=200
@export var aceleracion=1000
@export var friction=4500
var facing := 1


func _physics_process(delta):
	
	#gravedad
	if not is_on_floor():
		velocity.y = velocity.y + gravity * delta
		if velocity.y < 0:
			#$RedSuite.play("jump")
			$RedSuite.position.x = 0
			$RedSuite.position.y = 1
			$RedSuite.scale.x = facing
			$RedSuite.scale.y = 1
	
	#saltar
	var jump_pressed = Input.is_action_just_pressed("jump") and is_on_floor()
	if jump_pressed:
		velocity.y = velocity.y - jumpspeed
		
	var atake = Input.is_action_pressed("attack")

	#move
	var direction = Input.get_axis("left","right")
	
	
	if is_on_floor():
		if direction != 0 :
			if Input.is_action_pressed("run"):
				velocity.x = move_toward(velocity.x,direction * 2 * velocidad,aceleracion * delta)
				$RedSuite.play("run")
				if direction == 1 :
					facing= 1
				elif direction == -1 :
					facing= -1
				$RedSuite.position.x = 0
				$RedSuite.position.y = 0
				$RedSuite.scale.x = facing * 2.4
				$RedSuite.scale.y = 2.4
			else:
				velocity.x = move_toward(velocity.x,direction * velocidad,aceleracion * delta)
				$RedSuite.play("walk")
				if direction == 1 :
					facing= 1
				elif direction == -1 :
					facing= -1
				$RedSuite.position.x = 0
				$RedSuite.position.y = 0
				$RedSuite.scale.x = facing * 1.6
				$RedSuite.scale.y = 1.5
				
				
		else:
			velocity.x=move_toward(velocity.x,0,friction * delta)
			if atake:
				$RedSuite.play("hit")
				$RedSuite.position.x = 0
				$RedSuite.position.y = 0
				$RedSuite.scale.x = 1 * facing
				$RedSuite.scale.y = 1
				
			else:
				$RedSuite.play("idle")
				$RedSuite.position.x = 0
				$RedSuite.position.y = 0
				$RedSuite.scale.x = facing * 2
				$RedSuite.scale.y = 1 * 2
			
		
	else: 
		#$RedSuite.play("jump")
		$RedSuite.play("idle")
		$RedSuite.position.x = 0
		$RedSuite.position.y = 0
		$RedSuite.scale.x = facing * 2
		$RedSuite.scale.y = 1 * 2
		
	move_and_slide()
