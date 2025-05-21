extends VBoxContainer

# Boton 1
func _on_button_mouse_entered() -> void:
	$MoveSound.play()
func _on_button_pressed() -> void:
	$SelectSound.play()

# Boton 2
func _on_button_2_mouse_entered() -> void:
	$MoveSound.play()
func _on_button_2_pressed() -> void:
	$SelectSound.play()

# Boton 3
func _on_button_3_mouse_entered() -> void:
	$MoveSound.play()
func _on_button_3_pressed() -> void:
	$SelectSound.play()
