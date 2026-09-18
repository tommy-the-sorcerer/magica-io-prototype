class_name HUD
extends CanvasLayer

## Mobile In-Game HUD with Alive Counter, Dynamic Kill Feed, and Victory/Defeat Overlays

var alive_label: Label
var kills_label: Label
var kill_feed_container: VBoxContainer

var hp_bar: ProgressBar
var hp_label: Label
var level_label: Label
var xp_bar: ProgressBar

var victory_panel: Control
var defeat_panel: Control
var rank_label: Label
var restart_button_vic: Button
var restart_button_def: Button

var current_kills: int = 0
var _initialized: bool = false

func _ready() -> void:
	_ensure_initialized()
	if victory_panel:
		victory_panel.visible = false
	if defeat_panel:
		defeat_panel.visible = false
	if restart_button_vic:
		restart_button_vic.pressed.connect(_on_restart_pressed)
	if restart_button_def:
		restart_button_def.pressed.connect(_on_restart_pressed)

func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	alive_label = find_child("AliveLabel", true, false) as Label
	kills_label = find_child("KillsLabel", true, false) as Label
	kill_feed_container = find_child("KillFeedContainer", true, false) as VBoxContainer
	hp_bar = find_child("HPBar", true, false) as ProgressBar
	hp_label = find_child("HPLabel", true, false) as Label
	level_label = find_child("LevelLabel", true, false) as Label
	xp_bar = find_child("XPBar", true, false) as ProgressBar
	victory_panel = find_child("VictoryPanel", true, false) as Control
	defeat_panel = find_child("DefeatPanel", true, false) as Control
	rank_label = find_child("RankLabel", true, false) as Label
	
	if victory_panel:
		restart_button_vic = victory_panel.find_child("RestartButton", true, false) as Button
	if defeat_panel:
		restart_button_def = defeat_panel.find_child("RestartButton", true, false) as Button

func update_alive_count(alive: int, total: int = 15) -> void:
	_ensure_initialized()
	if alive_label:
		alive_label.text = "👤 Alive: %d / %d" % [alive, total]

func add_kill() -> void:
	_ensure_initialized()
	current_kills += 1
	if kills_label:
		kills_label.text = "⚔️ Kills: %d" % current_kills

func update_player_hp(curr: float, max_hp: float) -> void:
	_ensure_initialized()
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = curr
	if hp_label:
		hp_label.text = "%d / %d" % [int(curr), int(max_hp)]

func update_player_xp(curr_xp: float, max_xp: float, level: int) -> void:
	_ensure_initialized()
	if level_label:
		level_label.text = "Lv. %d" % level
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = curr_xp

func add_kill_feed(killer_name: String, victim_name: String, is_player_killer: bool) -> void:
	_ensure_initialized()
	if not kill_feed_container:
		return
		
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 14)
	
	if is_player_killer:
		label.text = "👑 YOU 💥 %s" % victim_name
		label.modulate = Color(1.0, 0.85, 0.2) # Gold
	else:
		label.text = "%s 💥 %s" % [killer_name, victim_name]
		label.modulate = Color(0.9, 0.9, 0.9, 0.85)
		
	kill_feed_container.add_child(label)
	
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func show_victory() -> void:
	_ensure_initialized()
	if victory_panel:
		victory_panel.visible = true
		var tween := create_tween()
		victory_panel.modulate.a = 0.0
		tween.tween_property(victory_panel, "modulate:a", 1.0, 0.5)

func show_defeat(final_rank: int) -> void:
	_ensure_initialized()
	if rank_label:
		rank_label.text = "RANK #%d" % final_rank
	if defeat_panel:
		defeat_panel.visible = true
		var tween := create_tween()
		defeat_panel.modulate.a = 0.0
		tween.tween_property(defeat_panel, "modulate:a", 1.0, 0.5)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
