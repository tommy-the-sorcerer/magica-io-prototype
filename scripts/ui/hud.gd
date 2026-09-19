class_name HUD
extends CanvasLayer

## Exact Magica.io Style Mobile HUD with 9-World Selection Carousel and Celestial Beam status

var alive_label: Label
var kills_label: Label
var level_label: Label
var xp_bar: ProgressBar
var kill_feed_container: VBoxContainer
var beam_label: Label
var shield_label: Label
var wind_label: Label
var skill_wind: Control
var _was_wind_ready: bool = true

var world_manager: WorldManager = null
var world_title_label: Label = null
var prev_world_btn: Button = null
var next_world_btn: Button = null

var victory_panel: Control
var defeat_panel: Control
var rank_label: Label
var restart_button_vic: Button
var restart_button_def: Button

var player_node: CharacterBody3D = null
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

func _process(_delta: float) -> void:
	_update_beam_status()
	_update_shield_status()
	_update_wind_status()

func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	alive_label = find_child("AliveLabel", true, false) as Label
	kills_label = find_child("KillsLabel", true, false) as Label
	level_label = find_child("LevelLabel", true, false) as Label
	xp_bar = find_child("XPBar", true, false) as ProgressBar
	kill_feed_container = find_child("KillFeedContainer", true, false) as VBoxContainer
	beam_label = find_child("BeamLabel", true, false) as Label
	shield_label = find_child("ShieldLabel", true, false) as Label
	wind_label = find_child("WindLabel", true, false) as Label
	
	# Connect clickable skill icons
	var skill_shield: Control = find_child("SkillShield", true, false) as Control
	if skill_shield:
		skill_shield.gui_input.connect(_on_skill_shield_gui_input)
	var skill_beam: Control = find_child("SkillBeam", true, false) as Control
	if skill_beam:
		skill_beam.gui_input.connect(_on_skill_beam_gui_input)
	skill_wind = find_child("SkillWind", true, false) as Control
	if skill_wind:
		skill_wind.pivot_offset = skill_wind.size * 0.5
		skill_wind.gui_input.connect(_on_skill_wind_gui_input)
	
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

	# Connect World Manager
	call_deferred("_connect_world_manager")

const CHAPTER_MAP_SCENES: Array[String] = [
	"res://scenes/maps/emerald_plains/emerald_plains.tscn",
	"res://scenes/maps/chapter_02_desert_mirage/desert_mirage.tscn",
	"res://scenes/maps/chapter_03_frostbite_tundra/frostbite_tundra.tscn",
	"res://scenes/maps/chapter_04_magma_core/magma_core.tscn",
	"res://scenes/maps/chapter_05_mystic_grove/mystic_grove.tscn",
	"res://scenes/maps/chapter_06_castle_ruins/castle_ruins.tscn",
	"res://scenes/maps/chapter_07_pirate_cove/pirate_cove.tscn",
	"res://scenes/maps/chapter_08_cursed_swamp/cursed_swamp.tscn",
	"res://scenes/maps/chapter_09_cosmic_void/cosmic_void.tscn",
	"res://scenes/maps/chapter_10_celestial_peak/celestial_peak.tscn",
]

const CHAPTER_NAMES: Array[String] = [
	"🌲 Emerald Plains",
	"🏜️ Desert Mirage",
	"❄️ Frostbite Tundra",
	"🌋 Magma Core",
	"🍄 Mystic Grove",
	"🏰 Castle Ruins",
	"🏴‍☠️ Pirate Cove",
	"🧟 Cursed Swamp",
	"🌌 Cosmic Void",
	"✨ Celestial Peak",
]

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
	else:
		var current_idx := _get_current_chapter_index()
		if world_title_label:
			world_title_label.text = CHAPTER_NAMES[current_idx]
		if prev_world_btn and not prev_world_btn.pressed.is_connected(_load_prev_chapter):
			prev_world_btn.pressed.connect(_load_prev_chapter)
		if next_world_btn and not next_world_btn.pressed.is_connected(_load_next_chapter):
			next_world_btn.pressed.connect(_load_next_chapter)

func _get_current_chapter_index() -> int:
	var cur_path := get_tree().current_scene.scene_file_path
	for i in range(CHAPTER_MAP_SCENES.size()):
		if CHAPTER_MAP_SCENES[i] == cur_path:
			return i
	return 0

func _load_prev_chapter() -> void:
	var idx := _get_current_chapter_index()
	var target := (idx - 1 + CHAPTER_MAP_SCENES.size()) % CHAPTER_MAP_SCENES.size()
	get_tree().change_scene_to_file(CHAPTER_MAP_SCENES[target])

func _load_next_chapter() -> void:
	var idx := _get_current_chapter_index()
	var target := (idx + 1) % CHAPTER_MAP_SCENES.size()
	get_tree().change_scene_to_file(CHAPTER_MAP_SCENES[target])

func _update_beam_status() -> void:
	var skill_beam: Control = find_child("SkillBeam", true, false) as Control
	if not player_node or not is_instance_valid(player_node):
		player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody3D
	
	if player_node and is_instance_valid(player_node):
		var cd = player_node.get("_beam_timer")
		var is_dragon: bool = false
		if cd == null:
			cd = player_node.get("_breath_timer")
			is_dragon = (cd != null)
		if cd == null:
			if skill_beam: skill_beam.visible = false
			return
		if skill_beam: skill_beam.visible = true
		if not beam_label: return
		var prefix: String = "🐲 [E]" if is_dragon else "☀️ [E]"
		if float(cd) <= 0.0:
			beam_label.text = "%s\nREADY" % prefix
			beam_label.modulate = Color(1.0, 1.0, 1.0)
		else:
			beam_label.text = "⏳ [E]\n%.1fs" % float(cd)
			beam_label.modulate = Color(0.8, 0.8, 0.8, 0.7)

func _update_shield_status() -> void:
	if not shield_label:
		return
	if not player_node or not is_instance_valid(player_node):
		player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody3D
	
	if player_node and is_instance_valid(player_node):
		var cd_val = player_node.get("_aegis_timer")
		if cd_val == null:
			cd_val = player_node.get("_shield_timer")
		if cd_val != null:
			var cd: float = float(cd_val)
			if cd <= 0.0:
				shield_label.text = "🛡️ [R]\nREADY"
				shield_label.modulate = Color(1.0, 1.0, 1.0)
			else:
				shield_label.text = "⏳ [R]\n%.1fs" % cd
				shield_label.modulate = Color(0.8, 0.8, 0.8, 0.7)

func _on_skill_shield_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not player_node or not is_instance_valid(player_node):
			player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody3D
		if player_node and is_instance_valid(player_node):
			if player_node.has_method("_cast_celestial_shield"):
				player_node.call("_cast_celestial_shield")
			elif player_node.has_method("_cast_electro_shield"):
				player_node.call("_cast_electro_shield")
			elif player_node.has_method("_cast_dragon_aegis"):
				player_node.call("_cast_dragon_aegis")

func _update_wind_status() -> void:
	if not wind_label:
		return
	if not player_node or not is_instance_valid(player_node):
		player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody3D
	
	if player_node and is_instance_valid(player_node):
		var cd_val = player_node.get("_dash_cd_timer")
		if cd_val != null:
			var cd: float = float(cd_val)
			if cd <= 0.0:
				wind_label.text = "⚡ [Q]\nREADY"
				wind_label.modulate = Color(1.0, 1.0, 1.0)
				if not _was_wind_ready:
					_was_wind_ready = true
					if skill_wind:
						var pt := create_tween()
						pt.tween_property(skill_wind, "scale", Vector2(1.18, 1.18), 0.12)
						pt.tween_property(skill_wind, "scale", Vector2.ONE, 0.15)
			else:
				_was_wind_ready = false
				wind_label.text = "⏳ [Q]\n%.1fs" % cd
				wind_label.modulate = Color(0.75, 0.75, 0.75, 0.65)

func _on_skill_wind_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not player_node or not is_instance_valid(player_node):
			player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody3D
		if player_node and is_instance_valid(player_node) and player_node.has_method("_perform_dash"):
			player_node.call("_perform_dash")

func _on_skill_beam_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not player_node or not is_instance_valid(player_node):
			player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody3D
		if player_node and is_instance_valid(player_node):
			if player_node.has_method("_cast_celestial_beam"):
				player_node.call("_cast_celestial_beam")
			elif player_node.has_method("_cast_dragon_breath"):
				player_node.call("_cast_dragon_breath")

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
			elif target_index < CHAPTER_MAP_SCENES.size():
				get_tree().change_scene_to_file(CHAPTER_MAP_SCENES[target_index])
		elif keycode == KEY_0:
			if world_manager:
				world_manager.apply_world(9)
			elif CHAPTER_MAP_SCENES.size() > 9:
				get_tree().change_scene_to_file(CHAPTER_MAP_SCENES[9])
		elif keycode == KEY_BRACKETLEFT or keycode == KEY_COMMA:
			if world_manager:
				world_manager.prev_world()
			else:
				_load_prev_chapter()
		elif keycode == KEY_BRACKETRIGHT or keycode == KEY_PERIOD:
			if world_manager:
				world_manager.next_world()
			else:
				_load_next_chapter()

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

func show_defeat(final_rank: int, _reason: String = "") -> void:
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
