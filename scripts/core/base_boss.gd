class_name BaseBoss
extends CharacterBody3D

## Reusable 4-Phase Boss Controller with health tracking, phase triggers, and arena coordination

signal phase_changed(new_phase: int)
signal boss_defeated

enum BossPhase { PHASE_1 = 1, PHASE_2 = 2, PHASE_3 = 3, PHASE_4 = 4 }

@export var boss_name: String = "Boss Guardian"
@export var max_health: float = 600.0
@export var move_speed: float = 4.0

var current_phase: BossPhase = BossPhase.PHASE_1
var is_active: bool = false
var can_act: bool = true

@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node3D = $Visuals
@onready var nameplate: Label3D = $Nameplate3D

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("bosses")
	
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		health_component.max_health = max_health
		add_child(health_component)
		
	health_component.max_health = max_health
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	
	_update_nameplate(health_component.current_health, health_component.max_health)

func activate_boss() -> void:
	is_active = true
	_enter_phase(BossPhase.PHASE_1)

func _enter_phase(phase: BossPhase) -> void:
	current_phase = phase
	phase_changed.emit(int(current_phase))
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
	nameplate.modulate = Color(1.0, 0.25, 0.2) if current_phase == BossPhase.PHASE_4 else Color(1.0, 0.85, 0.2)

func _on_died(_killer: Node) -> void:
	boss_defeated.emit()
	_on_boss_death()
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.3, 0.2, 1.3), 0.25)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.35)
	tween.tween_callback(queue_free)

# Virtual methods for chapter boss implementations to override
func _on_phase_entered(_phase: int) -> void:
	pass

func _on_boss_death() -> void:
	pass
