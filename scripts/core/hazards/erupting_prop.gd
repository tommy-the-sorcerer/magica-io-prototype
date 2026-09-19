class_name EruptingProp
extends Node3D

## State-driven recurring hazard (Volcano, Sand Geyser, Magma Vent, Spore Mushroom)
signal eruption_warning_started
signal eruption_triggered
signal eruption_ended

enum State { IDLE, WARNING, ERUPTING, COOLDOWN }

@export var idle_duration: float = 12.0
@export var warning_duration: float = 2.5
@export var eruption_duration: float = 3.5
@export var cooldown_duration: float = 3.0

var current_state: State = State.IDLE
var state_timer: float = 0.0

func _ready() -> void:
	state_timer = idle_duration

func _process(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_advance_state()

func _advance_state() -> void:
	match current_state:
		State.IDLE:
			current_state = State.WARNING
			state_timer = warning_duration
			eruption_warning_started.emit()
			_on_warning()
		State.WARNING:
			current_state = State.ERUPTING
			state_timer = eruption_duration
			eruption_triggered.emit()
			_on_eruption()
		State.ERUPTING:
			current_state = State.COOLDOWN
			state_timer = cooldown_duration
			eruption_ended.emit()
			_on_cooldown()
		State.COOLDOWN:
			current_state = State.IDLE
			state_timer = idle_duration
			_on_idle()

func _on_warning() -> void:
	pass

func _on_eruption() -> void:
	pass

func _on_cooldown() -> void:
	pass

func _on_idle() -> void:
	pass
