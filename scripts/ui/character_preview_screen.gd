class_name CharacterPreviewScreen
extends Control

## Dedicated Character Showcase & 360° Inspection Screen
## Connects UI input drag overlay with CharacterShowcase3D studio environment,
## displays hero lore & stats, and allows starting a match or returning home.

signal back_requested
signal play_requested

@onready var showcase_3d: Node3D = $SubViewportContainer/SubViewport/CharacterShowcase3D
@onready var drag_overlay: Control = $DragOverlay
@onready var back_button: Button = $TopBar/BackButton
@onready var play_button: Button = $RightPanel/PlayButton
@onready var reset_view_btn: Button = $CenterControls/ResetViewBtn
@onready var auto_spin_btn: Button = $CenterControls/AutoSpinBtn
@onready var abilities_btn: Button = $RightPanel/AbilitiesBtn
@onready var abilities_modal: PanelContainer = $AbilitiesModal
@onready var close_abilities_btn: Button = $AbilitiesModal/Margin/VBox/CloseBtn

var _is_auto_spinning: bool = false

func _ready() -> void:
	if drag_overlay:
		drag_overlay.gui_input.connect(_on_drag_overlay_gui_input)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	if play_button:
		play_button.pressed.connect(_on_play_pressed)

	if reset_view_btn:
		reset_view_btn.pressed.connect(_on_reset_view_pressed)

	if auto_spin_btn:
		auto_spin_btn.pressed.connect(_on_auto_spin_pressed)

	if abilities_btn:
		abilities_btn.pressed.connect(_on_abilities_pressed)

	if close_abilities_btn:
		close_abilities_btn.pressed.connect(func(): if abilities_modal: abilities_modal.visible = false)

	if abilities_modal:
		abilities_modal.visible = false

func _on_drag_overlay_gui_input(event: InputEvent) -> void:
	if showcase_3d:
		showcase_3d.handle_drag_input(event)

func _on_reset_view_pressed() -> void:
	if showcase_3d:
		showcase_3d.reset_view()

func _on_auto_spin_pressed() -> void:
	_is_auto_spinning = not _is_auto_spinning
	if showcase_3d:
		showcase_3d.auto_rotate_speed = 0.8 if _is_auto_spinning else 0.0
	if auto_spin_btn:
		auto_spin_btn.text = "⏸️ Stop Spin" if _is_auto_spinning else "▶️ Auto-Spin"

func _on_abilities_pressed() -> void:
	if abilities_modal:
		abilities_modal.visible = true

func _on_back_pressed() -> void:
	back_requested.emit()
	# If loaded standalone, return to home_screen.tscn
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/ui/home_screen.tscn")
	else:
		queue_free()

func _on_play_pressed() -> void:
	play_requested.emit()
	get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
