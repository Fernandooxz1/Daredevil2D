extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Tamer.play()
	AudioManager2.get_node("AudioStreamPlayer").stop()
	var health_comp = $Daredevil/HealthComponent
	var DD = $Daredevil
	var JuD = $Daredevil/Camera2D2/HUD
	
	health_comp.connect("onHealthChanged", Callable(JuD, "_on_health_changed"))
	health_comp.connect("onDead", Callable(DD,"_on_dead"))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
