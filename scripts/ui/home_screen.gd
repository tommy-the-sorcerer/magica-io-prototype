class_name HomeScreen
extends Control

## Main Hub / Home Screen for Magica IO / SpellArena
## Features a live 3D Arcane Apprentice preview, top resource bar,
## primary CTA Play button, and navigations for Character Showcase,
## Abilities, Progression/Pass, and Settings.

@onready var showcase_3d: Node3D = get_node_or_null("SubViewportContainer/SubViewport/CharacterShowcase3D") as Node3D
@onready var drag_overlay: Control = get_node_or_null("DragOverlay") as Control

@onready var play_btn: Button = find_child("PlayBtn", true, false) as Button
@onready var character_btn: Button = find_child("CharacterBtn", true, false) as Button
@onready var abilities_btn: Button = find_child("AbilitiesBtn", true, false) as Button
@onready var progression_btn: Button = find_child("ProgressionBtn", true, false) as Button
@onready var settings_btn: Button = find_child("SettingsBtn", true, false) as Button

@onready var info_modal: PanelContainer = find_child("InfoModal", true, false) as PanelContainer
@onready var modal_title: Label = find_child("ModalTitle", true, false) as Label
@onready var modal_body: Label = find_child("ModalBody", true, false) as Label
@onready var modal_close_btn: Button = find_child("ModalCloseBtn", true, false) as Button

func _ready() -> void:
	if showcase_3d:
		showcase_3d.auto_rotate_speed = 0.45

	if drag_overlay:
		drag_overlay.gui_input.connect(_on_drag_overlay_gui_input)

	if play_btn:
		play_btn.pressed.connect(_on_play_pressed)

	if character_btn:
		character_btn.pressed.connect(_on_character_pressed)

	if abilities_btn:
		abilities_btn.pressed.connect(_on_abilities_pressed)

	if progression_btn:
		progression_btn.pressed.connect(_on_progression_pressed)

	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)

	if modal_close_btn:
		modal_close_btn.pressed.connect(func(): if info_modal: info_modal.visible = false)

	if info_modal:
		info_modal.visible = false

func _on_drag_overlay_gui_input(event: InputEvent) -> void:
	if showcase_3d:
		showcase_3d.handle_drag_input(event)

func _on_play_pressed() -> void:
	# Transition directly to Emerald Plains Battle Royale Arena
	get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")

func _on_character_pressed() -> void:
	# Open dedicated 360° Character Preview Showcase
	get_tree().change_scene_to_file("res://scenes/ui/character_preview_screen.tscn")

func _on_abilities_pressed() -> void:
	_show_modal("⚡ ARCANE ABILITIES", 
		"✦ Primary Spell: ARCANE BOLT\nLaunches high-velocity magic bolts from the staff dealing 35 base damage.\n\n✦ Passive: ARCANE STRIDE\nEnhanced 360° agility, smooth movement interpolation, and responsive strafing.\n\n✦ Ultimate (Coming Soon): METEOR STORM\nSummon a barrage of celestial fragments across the arena.")

func _on_progression_pressed() -> void:
	_show_modal("🏆 SEASON 1: ARCANE FORGE", 
		"✦ Current Tier: Tier 4 / 30\n✦ Season XP: 450 / 1000\n\nNext Rewards:\n• Tier 5: 500 Gold 🪙\n• Tier 10: 50 Gems 💎\n• Tier 25: Exclusive Mage Robe Unlock")

func _on_settings_pressed() -> void:
	_show_modal("⚙️ GAME SETTINGS", 
		"✦ Graphics: Ultra (Mobile ACES Tonemap + HDR Bloom)\n✦ 3D Rendering: Mobile Vulkan / OpenGL\n✦ Master Volume: 100%\n✦ SFX & Spells: 100%\n✦ Control Mode: Virtual Dynamic Joystick + Tap Cast")

func _show_modal(title: String, body: String) -> void:
	if modal_title:
		modal_title.text = title
	if modal_body:
		modal_body.text = body
	if info_modal:
		info_modal.visible = true
