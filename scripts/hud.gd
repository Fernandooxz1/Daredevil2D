extends Node2D

# Rangos de salud y sus barras correspondientes
const HEALTH_BARS = [
	{"node": "TPB20", "min": 1, "max": 20},
	{"node": "TPB40", "min": 21, "max": 40},
	{"node": "TPB60", "min": 41, "max": 60},
	{"node": "TPB80", "min": 61, "max": 80},
	{"node": "TPB100", "min": 81, "max": 100},
]

func _ready() -> void:
	pass

func _on_health_changed(health: int) -> void:
	for bar_info in HEALTH_BARS:
		var bar = $HealthBar.get_node(bar_info["node"])
		bar.value = health
		bar.visible = (health >= bar_info["min"] and health <= bar_info["max"])

func _on_weapon_changed(weapon_id) -> void:
	$"Puños".visible = (weapon_id == 1)
	$"Baston".visible = (weapon_id == 2)
	$"Dual-wield".visible = (weapon_id == 3)
