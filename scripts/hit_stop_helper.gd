class_name HitStopHelper
extends RefCounted

static var _freeze_token: int = 0

## Realiza una micro-pausa (Hit-Stop / Freeze Frame) congelando Engine.time_scale durante `duration` segundos reales.
static func freeze(tree: SceneTree, duration: float = 0.04, time_scale: float = 0.0) -> void:
	if duration <= 0.0 or not tree:
		return
	_freeze_token += 1
	var token = _freeze_token
	Engine.time_scale = time_scale
	# Timer en tiempo real independiente de time_scale (ignore_time_scale = true)
	await tree.create_timer(duration, true, false, true).timeout
	if _freeze_token == token:
		Engine.time_scale = 1.0

## Restaura el time_scale al valor estándar de forma segura
static func reset() -> void:
	Engine.time_scale = 1.0
