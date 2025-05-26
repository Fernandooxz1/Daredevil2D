extends Area2D
class_name ProtaComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#area_entered.connect(take_item)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func take_item(obj):
	if obj is itemComponent:
		obj.take_item()
