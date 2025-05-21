extends CanvasLayer

# Pausar con Esc
func _physics_process(_delta):
	if Input.is_action_just_pressed("Pausa"):
		get_tree().paused = not get_tree().paused
		if $TextureRect.visible == true:
			$TextureRect.visible = false
		else : $TextureRect.visible = true
		
		if $Menu1.visible == true:
			$Menu1.visible = false
		elif $options.visible == true:
			$options.visible = false 
		else : $Menu1.visible = true
		
		if $options.visible == true:
			$options.visible = false
			
		if $TextureRect.visible == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		elif $TextureRect.visible == true: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
# Despausar si se presiona el boton1
func _on_button_pressed() -> void:
		get_tree().paused = not get_tree().paused
		$TextureRect.visible = not $TextureRect.visible
		$Menu1.visible = not $Menu1.visible
		if $TextureRect.visible == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		elif $TextureRect.visible == true: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_2_pressed() -> void:
	$Menu1.visible = not $Menu1.visible
	$options.visible = not $options.visible

func _on_button_3_pressed() -> void:
	get_tree().quit()
	
func _on_button_4_pressed() -> void:
	pass

func _on_button_5_pressed() -> void:
	pass

func _on_button_6_pressed() -> void:
	$Menu1.visible = not $Menu1.visible
	$options.visible = not $options.visible
