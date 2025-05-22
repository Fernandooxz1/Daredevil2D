extends Node2D

@onready var ladron = preload("res://scenes/ladron.tscn")
@onready var gasesito = preload("res://scenes/gas_venenoso.tscn")
@onready var health_comp = $Daredevil/HealthComponent
@onready var DD = $Daredevil
@onready var HuD = $Daredevil/Camera2D2/HUD
@onready var Ladron = $Ladron
@onready var health_comp_ladron = $Ladron/HealthComponent
@onready var primera_vez: int = 1
@onready var win: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Tamer.play()
	AudioManager2.get_node("AudioStreamPlayer").stop()
	
	health_comp.connect("onHealthChanged", Callable(HuD, "_on_health_changed"))
	health_comp_ladron.connect("onHealthChanged", Callable(Ladron, "_on_health_changed"))
	health_comp.connect("onDead", Callable(DD,"_on_dead"))
	
	crear(ladron,Vector2(2000,600)) # ladrones iniciales
	
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# crear ladrones que rodeen a daredevil si sobrepasa la coordenada "tal"
	if DD.position.x >= 3300 and primera_vez == 1:
		primera_vez = primera_vez + 1
		crear(ladron,Vector2(3000,540))
		crear(ladron,Vector2(3600,540))
		crear(gasesito,Vector2(3000,400))
		crear(gasesito,Vector2(3600,400))
	
	print(DD.position.x,"   ",DD.position.y)
	
	if DD.position.x >= 3700 and win == 1:
		win = win + 1
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func crear(sce,pos):
	var inst = sce.instantiate()
	add_child(inst)
	inst.position = pos
