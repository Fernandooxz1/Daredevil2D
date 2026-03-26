extends Control

@onready var volume_slider = $VBoxContainer/VolumeSlider
@onready var volume_label = $VBoxContainer/VolumeLabel

func _ready() -> void:
	var volume_db = AudioServer.get_bus_volume_db(0)
	var volume_pct = int(db_to_linear(volume_db) * 100)
	volume_slider.value = volume_pct
	volume_label.text = "Volumen: " + str(volume_pct) + "%"

func _on_volume_slider_changed(value: float) -> void:
	var linear_val = value / 100.0
	if linear_val <= 0.01:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(linear_val))
	volume_label.text = "Volumen: " + str(int(value)) + "%"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Options.tscn")

func _on_button_hover() -> void:
	$VBoxContainer/MoveSound.play()
