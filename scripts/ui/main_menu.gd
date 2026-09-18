class_name MainMenu
extends Control

## Main Menu / Lobby UI for Magica.io Mobile Battle Royale

@export var arena_scene_path: String = "res://scenes/arena/arena.tscn"
@export var matchmaking_scene: PackedScene

# Header UI Nodes
@onready var player_name_label: Label = %PlayerNameLabel if has_node("%PlayerNameLabel") else null
@onready var player_lvl_label: Label = %LevelLabel if has_node("%LevelLabel") else null
@onready var xp_bar: ProgressBar = %XPBar if has_node("%XPBar") else null
@onready var gold_label: Label = %GoldLabel if has_node("%GoldLabel") else null
@onready var gems_label: Label = %GemsLabel if has_node("%GemsLabel") else null

# Buttons
@onready var play_button: Button = %PlayButton if has_node("%PlayButton") else null
@onready var scores_button: Button = %ScoresButton if has_node("%ScoresButton") else null
@onready var settings_button: Button = %SettingsButton if has_node("%SettingsButton") else null
@onready var spellbook_button: Button = %SpellbookButton if has_node("%SpellbookButton") else null
@onready var rewards_button: Button = %RewardsButton if has_node("%RewardsButton") else null
@onready var missions_button: Button = %MissionsButton if has_node("%MissionsButton") else null
@onready var heroes_portal_btn: Button = %HeroesPortalButton if has_node("%HeroesPortalButton") else null
@onready var heroes_btn: Button = %HeroesButton if has_node("%HeroesButton") else null
@onready var shop_btn: Button = %ShopButton if has_node("%ShopButton") else null
@onready var watch_ads_btn: Button = %WatchAdsButton if has_node("%WatchAdsButton") else null

# 3D Hero Viewport Character
@onready var hero_3d: Node3D = %Hero3D if has_node("%Hero3D") else null

var _gold_amount: int = 1126
var _gem_amount: int = 0

func _ready() -> void:
	_setup_ui()
	_connect_buttons()
	_disable_hero_movement()

func _setup_ui() -> void:
	if player_name_label:
		player_name_label.text = "Player#5139"
	if player_lvl_label:
		player_lvl_label.text = "LVL 2"
	if xp_bar:
		xp_bar.max_value = 100
		xp_bar.value = 65
	if gold_label:
		gold_label.text = "%d" % _gold_amount
	if gems_label:
		gems_label.text = "%d" % _gem_amount

func _disable_hero_movement() -> void:
	if hero_3d:
		hero_3d.set_physics_process(false)
		hero_3d.set_process_unhandled_input(false)

func _process(delta: float) -> void:
	if hero_3d:
		var time := Time.get_ticks_msec() * 0.002
		hero_3d.rotation.y = sin(time * 0.5) * 0.15

func _connect_buttons() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		_add_button_animations(play_button)

	var all_buttons := [
		scores_button, settings_button, spellbook_button, rewards_button,
		missions_button, heroes_portal_btn, heroes_btn, shop_btn, watch_ads_btn
	]
	for btn in all_buttons:
		if btn:
			_add_button_animations(btn)

func _add_button_animations(btn: Button) -> void:
	btn.pivot_offset = btn.size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	
	btn.mouse_entered.connect(func():
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)
	btn.button_down.connect(func():
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05)
	)
	btn.button_up.connect(func():
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2.ONE, 0.05)
	)

func _on_play_pressed() -> void:
	var mm_res := load("res://scenes/ui/matchmaking_screen.tscn")
	if mm_res:
		var mm_instance := mm_res.instantiate() as Control
		add_child(mm_instance)
		if mm_instance.has_signal("match_found"):
			mm_instance.match_found.connect(func():
				get_tree().change_scene_to_file(arena_scene_path)
			)
		else:
			get_tree().change_scene_to_file(arena_scene_path)
	else:
		get_tree().change_scene_to_file(arena_scene_path)
