extends Node2D

@onready var thief_scene = preload("res://scenes/ladron.tscn")
@onready var poison_gas_scene = preload("res://scenes/gas_venenoso.tscn")
@onready var health_comp = $Daredevil/HealthComponent
@onready var player = $Daredevil
@onready var hud = $Daredevil/Camera2D2/HUD
@onready var thief = $Ladron
@onready var health_comp_thief = $Ladron/HealthComponent
@onready var first_wave_spawned: bool = false
@onready var level_completed: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Tamer.play()
	AudioManager2.get_node("AudioStreamPlayer").stop()

	health_comp.connect("on_health_changed", Callable(hud, "_on_health_changed"))
	health_comp_thief.connect("on_health_changed", Callable(thief, "_on_health_changed"))
	health_comp.connect("on_dead", Callable(player, "_on_dead"))

	spawn_instance(thief_scene, Vector2(2000, 600))

func _physics_process(_delta: float) -> void:
	# Crear ladrones cuando Daredevil pasa la coordenada 3300
	if player.position.x >= 3300 and not first_wave_spawned:
		first_wave_spawned = true
		spawn_instance(thief_scene, Vector2(3000, 540))
		spawn_instance(thief_scene, Vector2(3600, 540))
		spawn_instance(poison_gas_scene, Vector2(3000, 400))
		spawn_instance(poison_gas_scene, Vector2(3600, 400))

	# Victoria
	if player.position.x >= 3700 and not level_completed:
		level_completed = true
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func spawn_instance(scene, pos):
	var instance = scene.instantiate()
	add_child(instance)
	instance.position = pos
