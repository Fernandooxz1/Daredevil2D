extends CanvasLayer

# Pausar con Esc
func _physics_process(delta):
	if Input.is_action_just_pressed("Pausa"):
		get_tree().paused = not get_tree().paused
		$TextureRect.visible = not $TextureRect.visible
		$VBoxContainer.visible = not $VBoxContainer.visible
		if $TextureRect.visible == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		elif $TextureRect.visible == true: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
# Despausar si se presiona el boton1
func _on_button_pressed() -> void:
		get_tree().paused = not get_tree().paused
		$TextureRect.visible = not $TextureRect.visible
		$VBoxContainer.visible = not $VBoxContainer.visible
		if $TextureRect.visible == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		elif $TextureRect.visible == true: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_3_pressed() -> void:
	get_tree().quit()
