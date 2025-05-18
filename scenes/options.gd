extends Control

# Boton 1 "Graphics Settings"
func _on_button_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout	
	
# Boton 2 "Keyboard"
func _on_button_2_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_2_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout	
	
# Boton 3 "Back"
func _on_button_3_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_3_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout	
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
	
