class_name CharacterShowcase3D
extends Node3D

## Dedicated 3D Studio Showcase for 360° Character Inspection
## Supports continuous mouse drag & touch swipe rotation, inertia damping,
## and procedural idle breathing/crystal pulse animations.

@export var drag_sensitivity: float = 0.008
@export var inertia_damping: float = 8.0
@export var auto_rotate_speed: float = 0.0
@export var idle_bob_speed: float = 2.4
@export var idle_bob_amplitude: float = 0.015

var _is_dragging: bool = false
var _current_yaw: float = 0.0
var _target_yaw: float = 0.0
var _yaw_velocity: float = 0.0
var _last_drag_pos: Vector2 = Vector2.ZERO
var _anim_time: float = 0.0

@onready var character_pivot: Node3D = $CharacterPivot
@onready var staff_crystal_light: OmniLight3D = get_node_or_null("CharacterPivot/StaffCrystalLight") as OmniLight3D
@onready var pedestal_ring: MeshInstance3D = get_node_or_null("Pedestal/RunicRing") as MeshInstance3D

var anim_player: AnimationPlayer = null

func _ready() -> void:
	if character_pivot:
		_current_yaw = character_pivot.rotation.y
		_target_yaw = _current_yaw

		var default_cube := character_pivot.find_child("Cube", true, false) as Node3D
		if default_cube:
			default_cube.visible = false

		anim_player = character_pivot.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player:
			for cand in ["idle", "Idle", "IDLE", "showcase", "default"]:
				if anim_player.has_animation(cand):
					anim_player.play(cand)
					break

func _process(delta: float) -> void:
	_anim_time += delta

	# Handle 360° rotational interpolation with smooth inertia
	if auto_rotate_speed != 0.0 and not _is_dragging:
		_target_yaw += auto_rotate_speed * delta

	# Smooth damp towards target yaw
	_current_yaw = lerpf(_current_yaw, _target_yaw, inertia_damping * delta)

	if character_pivot:
		character_pivot.rotation.y = _current_yaw
		# Subtle idle breathing bobbing
		character_pivot.position.y = sin(_anim_time * idle_bob_speed) * idle_bob_amplitude

	# Pedestal magical runic ring slow rotation
	if pedestal_ring:
		pedestal_ring.rotation.y -= 0.5 * delta

	# Subtle staff crystal light pulse
	if staff_crystal_light:
		staff_crystal_light.light_energy = 0.8 + sin(_anim_time * 3.5) * 0.25

## External input hook called from UI Control touch/drag overlay
func handle_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_last_drag_pos = mb.position
				_yaw_velocity = 0.0
			else:
				_is_dragging = false

	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_is_dragging = true
			_last_drag_pos = st.position
			_yaw_velocity = 0.0
		else:
			_is_dragging = false

	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		var delta_x := mm.relative.x
		_target_yaw += delta_x * drag_sensitivity
		_yaw_velocity = delta_x * drag_sensitivity

	elif event is InputEventScreenDrag and _is_dragging:
		var sd := event as InputEventScreenDrag
		var delta_x := sd.relative.x
		_target_yaw += delta_x * drag_sensitivity
		_yaw_velocity = delta_x * drag_sensitivity

## Resets character rotation smoothly back to front facing (0°)
func reset_view() -> void:
	_target_yaw = 0.0
