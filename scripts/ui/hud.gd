class_name HUD
extends CanvasLayer

## Exact Magica.io Style Mobile HUD with 9-World Selection Carousel

var alive_label: Label
var kills_label: Label
var level_label: Label
var xp_bar: ProgressBar
var kill_feed_container: VBoxContainer

var world_manager: WorldManager = null
var world_title_label: Label = null
var prev_world_btn: Button = null
var next_world_btn: Button = null

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
	level_label = find_child("LevelLabel", true, false) as Label
	xp_bar = find_child("XPBar", true, false) as ProgressBar
	kill_feed_container = find_child("KillFeedContainer", true, false) as VBoxContainer
	
	world_title_label = find_child("WorldTitleLabel", true, false) as Label
	prev_world_btn = find_child("PrevWorldBtn", true, false) as Button
	next_world_btn = find_child("NextWorldBtn", true, false) as Button
	
	victory_panel = find_child("VictoryPanel", true, false) as Control
	defeat_panel = find_child("DefeatPanel", true, false) as Control
	rank_label = find_child("RankLabel", true, false) as Label
	
	if victory_panel:
		restart_button_vic = victory_panel.find_child("RestartButton", true, false) as Button
	if defeat_panel:
		restart_button_def = defeat_panel.find_child("RestartButton", true, false) as Button

	var attack_orb := find_child("Orb", true, false) as Control
	if attack_orb:
		attack_orb.gui_input.connect(_on_attack_orb_gui_input)

	var menu_btn := find_child("MenuBtn", true, false) as Button
	if menu_btn:
		menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/home_screen.tscn"))

	# Connect World Manager
	call_deferred("_connect_world_manager")

func _connect_world_manager() -> void:
	world_manager = get_tree().current_scene.find_child("WorldManager", true, false) as WorldManager
	if world_manager:
		if not world_manager.world_changed.is_connected(_on_world_changed):
			world_manager.world_changed.connect(_on_world_changed)
		if prev_world_btn and not prev_world_btn.pressed.is_connected(world_manager.prev_world):
			prev_world_btn.pressed.connect(world_manager.prev_world)
		if next_world_btn and not next_world_btn.pressed.is_connected(world_manager.next_world):
			next_world_btn.pressed.connect(world_manager.next_world)
		_on_world_changed(world_manager.current_world_index, world_manager.WORLDS_DATA[world_manager.current_world_index]["name"])

func _on_world_changed(_idx: int, wname: String) -> void:
	if world_title_label:
		world_title_label.text = wname

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode := (event as InputEventKey).keycode
		if keycode >= KEY_1 and keycode <= KEY_9:
			var target_index: int = keycode - KEY_1
			if world_manager:
				world_manager.apply_world(target_index)
		elif keycode == KEY_BRACKETLEFT or keycode == KEY_COMMA:
			if world_manager:
				world_manager.prev_world()
		elif keycode == KEY_BRACKETRIGHT or keycode == KEY_PERIOD:
			if world_manager:
				world_manager.next_world()

func update_alive_count(alive: int, _total: int = 15) -> void:
	_ensure_initialized()
	if alive_label:
		alive_label.text = "ALIVE: %d" % alive

func add_kill() -> void:
	_ensure_initialized()
	current_kills += 1
	if kills_label:
		kills_label.text = "KILLS: %d" % current_kills

func update_player_hp(_curr: float, _max_hp: float) -> void:
	pass

func update_player_xp(curr_xp: float, max_xp: float, level: int) -> void:
	_ensure_initialized()
	if level_label:
		level_label.text = "Level %d" % level
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
		label.modulate = Color(1.0, 0.85, 0.2)
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

func _on_attack_orb_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		var player := get_tree().current_scene.find_child("Player", true, false)
		if player:
			if player.has_method("_cast_spell"):
				player.call("_cast_spell")
			elif player.has_method("_cast_fireball"):
				player.call("_cast_fireball")

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
