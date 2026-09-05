extends Camera2D
class_name CameraDaredevil

static var current_camera: CameraDaredevil = null

@export var ciudad_node_path: NodePath  # asigná "Ciudad" desde el editor

# Sistema de Screen Shake por Trauma (Squirrel Eiserloh - Industry Standard)
@export var trauma_power: float = 2.0
@export var decay: float = 2.5
@export var max_offset: Vector2 = Vector2(18, 14)
@export var max_roll: float = 0.04

var trauma: float = 0.0
var base_offset: Vector2 = Vector2.ZERO
var base_rotation: float = 0.0
var _noise: FastNoiseLite = null
var _noise_i: float = 0.0

func _init() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 0.5
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func _ready() -> void:
	current_camera = self
	add_to_group("camera")
	base_offset = offset
	base_rotation = rotation

	set_camera_limits()

func _exit_tree() -> void:
	if current_camera == self:
		current_camera = null

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		var shake = pow(trauma, trauma_power)
		_noise_i += delta * 60.0
		offset.x = base_offset.x + max_offset.x * shake * _noise.get_noise_2d(_noise_i, 0.0)
		offset.y = base_offset.y + max_offset.y * shake * _noise.get_noise_2d(_noise_i, 100.0)
		rotation = base_rotation + max_roll * shake * _noise.get_noise_2d(_noise_i, 200.0)
	else:
		offset = base_offset
		rotation = base_rotation

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

static func shake(amount: float) -> void:
	if current_camera and is_instance_valid(current_camera):
		current_camera.add_trauma(amount)

func set_camera_limits():
	if ciudad_node_path.is_empty():
		return
	if not has_node(ciudad_node_path):
		return
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
