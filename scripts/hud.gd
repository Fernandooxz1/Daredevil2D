extends Node2D

# Rangos de salud y sus barras correspondientes
const HEALTH_BARS = [
	{"node": "TPB20", "min": 1, "max": 20},
	{"node": "TPB40", "min": 21, "max": 40},
	{"node": "TPB60", "min": 41, "max": 60},
	{"node": "TPB80", "min": 61, "max": 80},
	{"node": "TPB100", "min": 81, "max": 100},
]

enum RadarHUDState { EXPLORATION, COMBAT }
var current_hud_state: RadarHUDState = RadarHUDState.EXPLORATION

@onready var dd_sense: Sprite2D = $DdSense
@onready var sense_dd: Sprite2D = $SenseDd

var _dd_sense_base_scale: Vector2 = Vector2(0.059013, -0.0788568)
var _dd_sense_base_pos: Vector2 = Vector2(212.449, 496.052)
var _radar_pulse_tween: Tween = null
var _radar_shake_tween: Tween = null

func _ready() -> void:
	if dd_sense:
		_dd_sense_base_scale = dd_sense.scale
		_dd_sense_base_pos = dd_sense.position
	update_radar_hud_state(RadarHUDState.EXPLORATION)
	_connect_player_signals.call_deferred()

func _connect_player_signals() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = find_parent("Daredevil")
	if player:
		if player.has_signal("combat_stance_changed") and not player.combat_stance_changed.is_connected(_on_combat_stance_changed):
			player.combat_stance_changed.connect(_on_combat_stance_changed)
		if player.has_signal("radar_activated") and not player.radar_activated.is_connected(_on_radar_activated):
			player.radar_activated.connect(_on_radar_activated)
		if player.has_signal("radar_deactivated") and not player.radar_deactivated.is_connected(_on_radar_deactivated):
			player.radar_deactivated.connect(_on_radar_deactivated)

func _on_health_changed(health: int) -> void:
	for bar_info in HEALTH_BARS:
		var bar = $HealthBar.get_node(bar_info["node"])
		bar.value = health
		bar.visible = (health >= bar_info["min"] and health <= bar_info["max"])

func _on_weapon_changed(weapon_id) -> void:
	$"Puños".visible = (weapon_id == 1)
	$"Baston".visible = (weapon_id == 2)
	$"Dual-wield".visible = (weapon_id == 3)

# ==============================================================================
# RADAR SENSE & STANCE HUD
# ==============================================================================

func update_radar_hud_state(new_state: RadarHUDState) -> void:
	current_hud_state = new_state

	if _radar_pulse_tween and _radar_pulse_tween.is_valid():
		_radar_pulse_tween.kill()
		_radar_pulse_tween = null

	match new_state:
		RadarHUDState.EXPLORATION:
			if dd_sense:
				dd_sense.modulate = Color(1.0, 1.0, 1.0, 0.9)
				dd_sense.scale = _dd_sense_base_scale
			if sense_dd:
				sense_dd.modulate = Color(0.8, 0.25, 0.25, 0.65)

		RadarHUDState.COMBAT:
			if dd_sense:
				dd_sense.modulate = Color(2.5, 0.3, 0.3, 1.0) # Glow HDR activo
				var target_scale = Vector2(_dd_sense_base_scale.x * 1.15, _dd_sense_base_scale.y * 1.15)
				_radar_pulse_tween = create_tween().set_loops()
				_radar_pulse_tween.tween_property(dd_sense, "scale", target_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_radar_pulse_tween.tween_property(dd_sense, "scale", _dd_sense_base_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			if sense_dd:
				sense_dd.modulate = Color(1.8, 0.3, 0.3, 1.0)

func _on_combat_stance_changed(is_combat: bool) -> void:
	update_radar_hud_state(RadarHUDState.COMBAT if is_combat else RadarHUDState.EXPLORATION)

func _on_radar_activated(_duration: float = 0.0) -> void:
	update_radar_hud_state(RadarHUDState.COMBAT)

func _on_radar_deactivated() -> void:
	update_radar_hud_state(RadarHUDState.EXPLORATION)

func _on_radar_cooldown_updated(_remaining: float, _total: float) -> void:
	pass

func trigger_insufficient_energy_feedback() -> void:
	if not dd_sense:
		return

	if _radar_shake_tween and _radar_shake_tween.is_valid():
		_radar_shake_tween.kill()

	dd_sense.position = _dd_sense_base_pos
	_radar_shake_tween = create_tween()
	_radar_shake_tween.tween_property(dd_sense, "modulate", Color(0.6, 0.1, 0.1, 1.0), 0.08)
	_radar_shake_tween.tween_property(dd_sense, "position:x", _dd_sense_base_pos.x + 6.0, 0.04)
	_radar_shake_tween.tween_property(dd_sense, "position:x", _dd_sense_base_pos.x - 6.0, 0.04)
	_radar_shake_tween.tween_property(dd_sense, "position:x", _dd_sense_base_pos.x + 4.0, 0.04)
	_radar_shake_tween.tween_property(dd_sense, "position:x", _dd_sense_base_pos.x, 0.04)
	_radar_shake_tween.tween_property(dd_sense, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
