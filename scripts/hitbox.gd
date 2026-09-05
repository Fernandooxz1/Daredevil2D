extends Area2D
class_name HitboxComponent

signal on_hit_landed(target_area: HealthComponent, hit_data: Dictionary)

@export var damage: int = 2

var attack_type: String = "hit1"
var combo_step: int = 1
var hit_stop_duration: float = 0.04
var trauma_amount: float = 0.15
var attacker: Node2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area) -> void:
	if area is HealthComponent:
		var source = attacker if attacker else owner
		var hit_direction = 1
		if source and "facing" in source:
			hit_direction = int(source.facing)

		var hit_data: Dictionary = {
			"damage": damage,
			"attack_type": attack_type,
			"combo_step": combo_step,
			"hit_stop": hit_stop_duration,
			"trauma": trauma_amount,
			"attacker": source,
			"direction": hit_direction,
			"hitbox": self
		}

		area.take_damage(damage, hit_data)
		on_hit_landed.emit(area, hit_data)

		var tree: SceneTree = get_tree() if is_inside_tree() else null

		# Micro-pausa de impacto (Hit-stop / freeze frame)
		if hit_stop_duration > 0.0 and tree:
			HitStopHelper.freeze(tree, hit_stop_duration)

		# Screen shake por trauma en la cámara
		if trauma_amount > 0.0:
			CameraDaredevil.shake(trauma_amount)
			if tree:
				tree.call_group("camera", "add_trauma", trauma_amount)

		# Efectos visuales de partículas (VFX) según atacante y contundencia:
		# Si golpea Daredevil -> chispas / impacto pesado con sangre
		# Si golpea el Ladrón -> impacto contuso sutil sin sangre (BluntHit)
		var spawn_parent: Node = tree.current_scene if tree and tree.current_scene else (owner.get_parent() if owner and owner.get_parent() else (source.get_parent() if source and source.get_parent() else (get_parent() if get_parent() else self)))
		var contact_pos: Vector2 = (global_position + area.global_position) * 0.5
		var hit_dir: Vector2 = Vector2(float(hit_direction), -0.25).normalized()

		var target_is_player: bool = (area.owner != null and area.owner.is_in_group("player")) or (area.get_parent() != null and area.get_parent().is_in_group("player"))
		var is_player_attacker: bool = ((source != null and source.is_in_group("player")) or (owner != null and owner.is_in_group("player"))) and not target_is_player
		if is_player_attacker:
			if attack_type == "hit4" or attack_type == "kick" or attack_type == "boo3":
				HeavyImpact.spawn(spawn_parent, contact_pos, hit_dir)
			else:
				HitSparks.spawn(spawn_parent, contact_pos, hit_dir)
		else:
			BluntHit.spawn(spawn_parent, contact_pos, hit_dir)

func _on_health_component_on_dead() -> void:
	pass
