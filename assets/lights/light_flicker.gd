extends PointLight2D
class_name LightFlicker

enum FlickerMode {
	NONE,
	SUBTLE_HUM,    # Leve oscilación de voltaje para farolas de vapor de sodio
	NEON_GLITCH,   # Micro-caídas y parpadeos aleatorios para carteles de neón defectuosos
	STROBE         # Alarma o relámpago intermitente
}

@export var mode: FlickerMode = FlickerMode.SUBTLE_HUM
@export var base_energy: float = 1.6
@export var flicker_intensity: float = 0.15
@export var speed: float = 12.0

var _noise_time: float = 0.0
var _glitch_timer: float = 0.0

func _ready() -> void:
	if base_energy <= 0.0:
		base_energy = energy
	_noise_time = randf() * 100.0

func _process(delta: float) -> void:
	match mode:
		FlickerMode.NONE:
			energy = base_energy
		FlickerMode.SUBTLE_HUM:
			_noise_time += delta * speed
			var wave = sin(_noise_time) * 0.5 + sin(_noise_time * 2.7) * 0.3
			energy = base_energy + (wave * flicker_intensity)
		FlickerMode.NEON_GLITCH:
			_glitch_timer -= delta
			if _glitch_timer <= 0.0:
				if randf() < 0.12:
					energy = base_energy * randf_range(0.1, 0.4)
					_glitch_timer = randf_range(0.04, 0.12)
				else:
					energy = base_energy * randf_range(0.92, 1.05)
					_glitch_timer = randf_range(0.2, 1.5)
		FlickerMode.STROBE:
			_noise_time += delta * speed
			energy = base_energy if fmod(_noise_time, 2.0) > 1.0 else 0.0
