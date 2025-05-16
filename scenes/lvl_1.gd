@onready var camara: Camera2D = $Daredevil/Camera2D

func _ready():
	configurar_limites_camara()

func configurar_limites_camara():
	# Obtenés las referencias correctamente
	var nodos_ciudad = [
		get_node("Cuidad"),
		get_node("CuidadClon"),
		get_node("CuidadClon2"),
		get_node("CuidadClon3"),
		get_node("CuidadClon4")
	]

	var left = INF
	var right = -INF
	var top = INF
	var bottom = -INF

	for nodo in nodos_ciudad:
		var sprite = nodo.get_node("Sprite2D")  # Asegurate de que el nodo se llama así
		var size = sprite.texture.get_size()
		var global_pos = sprite.global_position

		var sprite_left = global_pos.x - size.x / 2
		var sprite_right = global_pos.x + size.x / 2
		var sprite_top = global_pos.y - size.y / 2
		var sprite_bottom = global_pos.y + size.y / 2

		left = min(left, sprite_left)
		right = max(right, sprite_right)
		top = min(top, sprite_top)
		bottom = max(bottom, sprite_bottom)

	var half_screen = get_viewport_rect().size * 0.5

	camara.limit_left = int(left + half_screen.x)
	camara.limit_right = int(right - half_screen.x)
	camara.limit_top = int(top + half_screen.y)
	camara.limit_bottom = int(bottom - half_screen.y)
