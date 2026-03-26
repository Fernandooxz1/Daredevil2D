extends Node2D

@onready var gas_sfx = $GasSFX

func _ready() -> void:
	$AnimatedSprite2D.play("Gasesito")
	gas_sfx.finished.connect(_on_gas_sfx_finished)

func _on_gas_sfx_finished() -> void:
	gas_sfx.play()
