extends Camera2D

@export var ciudad_node_path: NodePath  # asigná "Ciudad" desde el editor

func _ready():
	set_camera_limits()

func set_camera_limits():
	var ciudad = get_node(ciudad_node_path)

	if ciudad and ciudad is Sprite2D:
		var texture_size = ciudad.texture.get_size()
		var ciudad_global_pos = ciudad.global_position

		# Calculamos los bordes del fondo
		var half_screen = get_viewport_rect().size * 0.5

		limit_left = int(ciudad_global_pos.x - texture_size.x / 2 + half_screen.x)
		limit_right = int(ciudad_global_pos.x + texture_size.x / 2 - half_screen.x)
		limit_top = int(ciudad_global_pos.y - texture_size.y / 2 + half_screen.y)
		limit_bottom = int(ciudad_global_pos.y + texture_size.y / 2 - half_screen.y)
