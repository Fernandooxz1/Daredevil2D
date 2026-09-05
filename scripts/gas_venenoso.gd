extends Node2D

@onready var gas_sfx = $GasSFX
@onready var col_shape = $HitBox/CollisionShape2D

var effective_radius: float = 75.0
var col_center: Vector2 = Vector2(-1, 4)
var is_radar_visible: bool = false
var radar_ping_alpha: float = 0.0
var _ping_tween: Tween = null
var pulse_time: float = 0.0
var sound_wave_time: float = 0.0

func _ready() -> void:
	add_to_group("detectables")
	$AnimatedSprite2D.play("Gasesito")
	gas_sfx.finished.connect(_on_gas_sfx_finished)

	if col_shape:
		col_center = col_shape.position
		if col_shape.shape is CircleShape2D:
			effective_radius = (col_shape.shape as CircleShape2D).radius * col_shape.scale.x
		else:
			effective_radius = 10.0 * col_shape.scale.x

func _on_gas_sfx_finished() -> void:
	gas_sfx.play()

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player and get_parent():
		player = get_parent().find_child("Daredevil", true, false)

	var active_now: bool = (player != null and (player.get("is_combat_stance") == true or player.get("is_radar_active") == true))
	if active_now:
		pulse_time += delta * 4.0
		sound_wave_time += delta * 3.5
		is_radar_visible = true
		queue_redraw()
	elif is_radar_visible:
		is_radar_visible = false
		queue_redraw()
	elif radar_ping_alpha > 0.0:
		sound_wave_time += delta * 3.5
		queue_redraw()

func on_radar_ping(origin: Vector2, radius: float) -> void:
	var dist = global_position.distance_to(origin)
	if dist <= radius:
		if _ping_tween and _ping_tween.is_valid():
			_ping_tween.kill()
		radar_ping_alpha = 1.0
		_ping_tween = create_tween()
		_ping_tween.tween_property(self, "radar_ping_alpha", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var alpha: float = 0.0
	if is_radar_visible:
		alpha = 0.75 + 0.2 * sin(pulse_time)
	elif radar_ping_alpha > 0.0:
		alpha = radar_ping_alpha * 0.8

	if alpha <= 0.01:
		return

	# 1. Borde borroso de peligro acustico
	# Matt no percibe el humo visualmente sino el area de dispersion difusa con un degradado suave
	var num_rings: int = 10
	var blur_spread: float = 20.0
	for i in range(num_rings):
		var t: float = (float(i) / float(num_rings - 1)) * 2.0 - 1.0
		var r: float = effective_radius + t * (blur_spread * 0.5)
		var weight: float = exp(-t * t * 2.2)
		var ring_alpha: float = alpha * weight * 0.11
		draw_arc(col_center, r, 0.0, TAU, 48, Color(2.4, 0.45, 0.15, ring_alpha), 2.0)

	# Relleno interior difuso muy suave
	draw_circle(col_center, max(effective_radius - blur_spread * 0.5, 5.0), Color(1.3, 0.25, 0.1, alpha * 0.05))

	# 2. Origen del sonido (la fuga de gas que Matt escucha acusticamente)
	# Ondas acusticas concentricas que se expanden ritmicamente desde el escape de gas (0 a ~22px)
	var num_sound_waves: int = 3
	var max_wave_dist: float = 22.0
	for w in range(num_sound_waves):
		var phase: float = fmod(sound_wave_time * 0.75 + float(w) / float(num_sound_waves), 1.0)
		var wave_r: float = 3.0 + phase * (max_wave_dist - 3.0)
		var wave_a: float = alpha * (1.0 - phase) * 0.85
		var wave_col = Color(2.8, 0.65, 0.2, wave_a)
		draw_arc(col_center, wave_r, 0.0, TAU, 28, wave_col, 1.6)

	# Nucleo central del orificio de escape de gas
	draw_circle(col_center, 2.5, Color(3.2, 0.8, 0.25, alpha * 0.95))
