extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	# Aquí podrías actualizar una barra de vida, por ejemplo:
	
func _on_health_changed(health: int) -> void:
	$HealthBar/TPB100.value = health
	$HealthBar/TPB80.value = health
	$HealthBar/TPB60.value = health
	$HealthBar/TPB40.value = health
	$HealthBar/TPB20.value = health
	if health > 80 and health <= 100 :
		$HealthBar/TPB100.visible = true
		$HealthBar/TPB80.visible = false
		$HealthBar/TPB60.visible = false
		$HealthBar/TPB40.visible = false
		$HealthBar/TPB20.visible = false
	elif health > 60 and health <= 80 :
		$HealthBar/TPB100.visible = false
		$HealthBar/TPB80.visible = true
		$HealthBar/TPB60.visible = false
		$HealthBar/TPB40.visible = false
		$HealthBar/TPB20.visible = false
	elif health > 40 and health <= 60 :
		$HealthBar/TPB100.visible = false
		$HealthBar/TPB80.visible = false
		$HealthBar/TPB60.visible = true
		$HealthBar/TPB40.visible = false
		$HealthBar/TPB20.visible = false
	elif health > 20 and health <= 40 :
		$HealthBar/TPB100.visible = false
		$HealthBar/TPB80.visible = false
		$HealthBar/TPB60.visible = false
		$HealthBar/TPB40.visible = true
		$HealthBar/TPB20.visible = false
	elif health > 0 and health <= 20 :
		$HealthBar/TPB100.visible = false
		$HealthBar/TPB80.visible = false
		$HealthBar/TPB60.visible = false
		$HealthBar/TPB40.visible = false
		$HealthBar/TPB20.visible = true


func _on_daredevil_actual_weapon(arma_actual) -> void:
	if arma_actual == 1:
		$"Puños".visible = true
		$"Baston".visible = false
		$"Dual-wield".visible = false
	elif arma_actual == 2:
		$"Puños".visible = false
		$"Baston".visible = true
		$"Dual-wield".visible = false
	elif arma_actual == 3:
		$"Puños".visible = false
		$"Baston".visible = false
		$"Dual-wield".visible = true
	else:
		$"Puños".visible = false
		$"Baston".visible = false
		$"Dual-wield".visible = false
