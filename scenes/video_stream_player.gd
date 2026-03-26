extends Control

# Referencias a los nodos
@onready var video_player = $VideoStreamPlayer
@onready var botones = $VBoxContainer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Si no activaste Autoplay en el editor
	video_player.play()
	
	# Opcional: Ocultar botones al inicio para que se vea el video
	# botones.hide()
	
	# Conectar la señal de cuando termina el video
	video_player.finished.connect(_on_video_finished)

func _on_video_finished():
	# Acción cuando termina el video, por ejemplo, mostrar botones
	botones.show()
	# O si quieres que el video se repita en bucle:
	#video_player.play()

# Mantienes tus funciones de botones existentes
func _on_button_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/lvl_1.tscn")

func _on_button_2_pressed() -> void:
	$VBoxContainer/SelectSound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
