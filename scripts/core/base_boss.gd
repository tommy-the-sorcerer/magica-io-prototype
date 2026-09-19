class_name BaseBoss
extends CharacterBody3D

## Reusable 4-Phase Boss Controller with health tracking, phase triggers, and lethal telegraphed attacks

signal phase_changed(new_phase: int)
signal boss_defeated
signal boss_attack_slammed(pos: Vector3, strength: float)

enum BossPhase { PHASE_1 = 1, PHASE_2 = 2, PHASE_3 = 3, PHASE_4 = 4 }

@export var boss_name: String = "Boss Guardian"
@export var max_health: float = 750.0
@export var move_speed: float = 4.2
@export var attack_range: float = 4.5
@export var attack_damage: float = 35.0

var current_phase: BossPhase = BossPhase.PHASE_1
var is_active: bool = false
var can_act: bool = true
var target_player: Node3D = null

@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node3D = $Visuals
@onready var nameplate: Label3D = $Nameplate3D

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("bosses")
	
	if not health_component:
		health_component = find_child("HealthComponent", true, false) as HealthComponent
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		health_component.max_health = max_health
		add_child(health_component)
		
	health_component.max_health = max_health
	health_component.current_health = max_health
	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
	
	_update_nameplate(health_component.current_health, health_component.max_health)
	activate_boss()

func activate_boss() -> void:
	is_active = true
	_find_player()
	_enter_phase(BossPhase.PHASE_1)

func _find_player() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	var players := tree.get_nodes_in_group("players")
	if players.is_empty():
		players = tree.get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0] as Node3D

func _enter_phase(phase: BossPhase) -> void:
	current_phase = phase
	phase_changed.emit(int(current_phase))
	
	# Phase 4 Enrage Buff
	if current_phase == BossPhase.PHASE_4:
		move_speed *= 1.35
		attack_damage *= 1.4
		if visuals:
			var tween := create_tween()
			if tween:
				tween.tween_property(visuals, "scale", visuals.scale * 1.15, 0.4).set_trans(Tween.TRANS_BACK)
			
	_on_phase_entered(int(current_phase))

func _on_health_changed(curr: float, max_hp: float) -> void:
	_update_nameplate(curr, max_hp)
	var hp_pct: float = curr / maxf(max_hp, 1.0)
	
	if hp_pct <= 0.25 and current_phase < BossPhase.PHASE_4:
		_enter_phase(BossPhase.PHASE_4)
	elif hp_pct <= 0.50 and current_phase < BossPhase.PHASE_3:
		_enter_phase(BossPhase.PHASE_3)
	elif hp_pct <= 0.75 and current_phase < BossPhase.PHASE_2:
		_enter_phase(BossPhase.PHASE_2)

func _update_nameplate(curr: float, max_hp: float) -> void:
	if not nameplate:
		return
	var hp_pct: float = clampf(curr / maxf(max_hp, 1.0), 0.0, 1.0)
	var bar_len: int = 14
	var filled: int = int(hp_pct * bar_len)
	var bar_str: String = "█".repeat(filled) + "░".repeat(bar_len - filled)
	nameplate.text = "👑 %s (PHASE %d)\n[%s] %d / %d" % [boss_name, int(current_phase), bar_str, int(curr), int(max_hp)]
	nameplate.modulate = Color(1.0, 0.15, 0.1) if current_phase == BossPhase.PHASE_4 else (Color(1.0, 0.55, 0.1) if current_phase >= BossPhase.PHASE_2 else Color(1.0, 0.9, 0.2))

func _on_died(_killer: Node) -> void:
	boss_defeated.emit()
	_on_boss_death()
	
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector3(1.4, 0.1, 1.4), 0.3).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(self, "scale", Vector3.ZERO, 0.4)
		tween.tween_callback(queue_free)

## Helper: Creates a ground telegraph circle indicating where a violent attack will hit
func create_telegraph_circle(pos: Vector3, radius: float, duration: float, color: Color = Color(1, 0.2, 0.1, 0.6)) -> MeshInstance3D:
	var circle := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.08
	circle.mesh = cylinder
	
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	circle.material_override = mat
	
	var parent_node: Node = get_parent() if get_parent() else self
	parent_node.add_child(circle)
	if is_inside_tree() and parent_node.is_inside_tree():
		circle.global_position = Vector3(pos.x, 0.05, pos.z)
	else:
		circle.position = Vector3(pos.x, 0.05, pos.z)
	
	# Expanding animation
	circle.scale = Vector3(0.1, 1.0, 0.1)
	var tween := create_tween()
	if tween:
		tween.tween_property(circle, "scale", Vector3(1.0, 1.0, 1.0), duration)
		tween.tween_callback(circle.queue_free)
	
	return circle

## Helper: Face target smoothly
func look_at_target(target_pos: Vector3, delta: float) -> void:
	var dir := (target_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 8.0 * delta)

# Virtual methods for chapter boss implementations to override
func _on_phase_entered(_phase: int) -> void:
	pass

func _on_boss_death() -> void:
	pass
