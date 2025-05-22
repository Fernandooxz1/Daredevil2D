class_name AudioManager
extends Control

func _ready() -> void:
	if not AudioManager2.get_node("AudioStreamPlayer").playing:
		AudioManager2.get_node("AudioStreamPlayer").play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Boton 1 "Play"
func _on_button_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/lvl_1.tscn")

# Boton 2 "Options"
func _on_button_2_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_2_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/Options.tscn")

# Boton 3 "Quit"
func _on_button_3_mouse_entered() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_3_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
