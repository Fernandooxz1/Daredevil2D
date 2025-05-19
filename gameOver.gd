extends Control
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
# Boton 1 "Continue"
func _on_button_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout	
	get_tree().change_scene_to_file("res://scenes/lvl_1.tscn")

# Boton 2 "Main Menu"
func _on_button_2_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_2_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout	
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
