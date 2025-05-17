
extends Control

func _on_button_pressed() -> void:
	pass # Configuracion


func _on_button_2_pressed() -> void:
	pass # Teclado


func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
