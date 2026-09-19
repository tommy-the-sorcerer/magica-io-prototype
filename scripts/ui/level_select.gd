extends Control

## LudusForge 100-Level Eldritch Path Progression Map Controller
## Full Kenney Assets Integration + 2400x1350 Pannable & Zoomable World Map,
## Dual-layer Glowing Spark Line, Fantasy UI Borders, and 7 Distinct Regions.

signal level_selected(level_number: int)

# Viewport & World Panning
@onready var map_viewport: Control = $MapViewport
@onready var map_world: Control = $MapViewport/MapWorld
@onready var spark_line_glow: Line2D = $MapViewport/MapWorld/SparkLineGlow
@onready var spark_line_core: Line2D = $MapViewport/MapWorld/SparkLineCore
@onready var nodes_container: Control = $MapViewport/MapWorld/NodesContainer
@onready var landmarks_container: Control = $MapViewport/MapWorld/LandmarksContainer
@onready var region_labels_container: Control = $MapViewport/MapWorld/RegionLabelsContainer

# Floating HUD & Legends
@onready var region_badge: Control = $RegionHUD
@onready var region_label: Label = $RegionHUD/RegionLabel
@onready var toast_panel: Control = $Toast
@onready var toast_label: Label = $Toast/ToastLabel

# Modal & Controls
@onready var modal_panel: Control = $LevelInfoModal
@onready var modal_card: Control = $LevelInfoModal/Card
@onready var modal_close_btn: Button = $LevelInfoModal/Card/CloseBtn
@onready var level_title_label: Label = $LevelInfoModal/Card/VBox/LevelTitle
@onready var region_name_label: Label = $LevelInfoModal/Card/VBox/RegionName
@onready var difficulty_label: Label = $LevelInfoModal/Card/VBox/DifficultyLabel
@onready var objective_label: Label = $LevelInfoModal/Card/VBox/ObjectiveText
@onready var reward_label: Label = $LevelInfoModal/Card/VBox/RewardText
@onready var start_btn: Button = $LevelInfoModal/Card/VBox/StartLevelBtn

# Top Bar
@onready var back_menu_btn: Button = $TopBar/BackBtn
@onready var close_map_btn: Button = $TopBar/CloseMapBtn
@onready var coins_label: Label = $TopBar/Currencies/Gold
@onready var gems_label: Label = $TopBar/Currencies/Gems

var level_mgr: LevelManager = null
var selected_level_num: int = 1

# Camera Panning & Zooming
const WORLD_SIZE: Vector2 = Vector2(2400, 1350)
var is_dragging: bool = false
var drag_moved: bool = false
var btn_drag_moved: bool = false
var drag_mouse_start: Vector2 = Vector2.ZERO
var drag_world_start: Vector2 = Vector2.ZERO
var target_map_pos: Vector2 = Vector2.ZERO
var target_zoom: float = 0.95
var current_zoom: float = 0.95
const MIN_ZOOM: float = 0.35
const MAX_ZOOM: float = 2.20

var toast_tween: Tween = null

func _ready() -> void:
	level_mgr = LevelManager.instance if LevelManager.instance else LevelManager.new()
	if not LevelManager.instance:
		add_child(level_mgr)
	if level_mgr:
		level_mgr.load_progression()
		
	var min_fit := _get_min_fit_zoom()
	target_zoom = maxf(min_fit, 0.82)
	current_zoom = target_zoom
		
	_setup_ui_events()
	_update_topbar_currencies()
	_spawn_kenney_landmarks()
	_spawn_region_banners()
	_build_100_level_progression()
	
	call_deferred("_center_camera_on_current_level")
	_animate_ui_entry()

func _setup_ui_events() -> void:
	if back_menu_btn:
		back_menu_btn.pressed.connect(_on_return_menu)
	if close_map_btn:
		close_map_btn.pressed.connect(_on_return_menu)
		
	if modal_close_btn:
		modal_close_btn.pressed.connect(close_level_modal)
	if start_btn:
		start_btn.pressed.connect(_on_start_selected_level)
		
	if modal_panel:
		modal_panel.visible = false
		modal_panel.mouse_filter = MOUSE_FILTER_IGNORE
		modal_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				close_level_modal()
		)
		
	if map_viewport:
		map_viewport.gui_input.connect(_on_viewport_gui_input)

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _set_drag_cursor(dragging: bool) -> void:
	if dragging:
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _get_min_fit_zoom() -> float:
	var vp_size: Vector2 = map_viewport.size if map_viewport and map_viewport.size.x > 0 else get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return 0.55
	return maxf(vp_size.x / WORLD_SIZE.x, vp_size.y / WORLD_SIZE.y)

func _process(delta: float) -> void:
	# Keyboard Left / Right / Up / Down pan navigation for smooth movements
	var pan_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_dir.x += 1.0 # Move map right / camera left
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_dir.x -= 1.0 # Move map left / camera right
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_dir.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_dir.y -= 1.0
		
	if pan_dir != Vector2.ZERO and not (modal_panel and modal_panel.visible):
		var pan_speed := 950.0
		target_map_pos += pan_dir.normalized() * pan_speed * delta
		_clamp_camera_bounds()

	# Smooth Camera Panning when not actively dragging
	if not is_dragging:
		map_world.position = map_world.position.lerp(target_map_pos, delta * 14.0)
	else:
		map_world.position = target_map_pos
	
	# Smooth Zooming
	current_zoom = lerpf(current_zoom, target_zoom, delta * 12.0)
	map_world.scale = Vector2(current_zoom, current_zoom)
	
	_clamp_camera_bounds()
	_update_current_region_hud()

func _input(event: InputEvent) -> void:
	if modal_panel and modal_panel.visible:
		return
	_handle_pan_zoom(event)

func _unhandled_input(event: InputEvent) -> void:
	if modal_panel and modal_panel.visible:
		return
	_handle_pan_zoom(event)

func _on_viewport_gui_input(event: InputEvent) -> void:
	if modal_panel and modal_panel.visible:
		return
	_handle_pan_zoom(event)

func _handle_pan_zoom(event: InputEvent) -> void:
	# Mouse Drag / Pan with Right-Click OR Left-Click
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				drag_moved = false
				drag_mouse_start = mb.position
				drag_world_start = target_map_pos
				_set_drag_cursor(true)
			else:
				is_dragging = false
				_set_drag_cursor(false)
		# Mouse Wheel Zoom
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(0.08 * target_zoom, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(-0.08 * target_zoom, mb.position)
			
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if is_dragging or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			drag_moved = true
			is_dragging = true
			_set_drag_cursor(true)
			target_map_pos += mm.relative
			_clamp_camera_bounds()
			map_world.position = target_map_pos
			
	# Mobile Touch Drag
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			is_dragging = true
			drag_moved = false
		else:
			is_dragging = false
			
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		drag_moved = true
		target_map_pos += sd.relative
		_clamp_camera_bounds()
		map_world.position = target_map_pos

func _apply_zoom(zoom_delta: float, pivot_pos: Vector2) -> void:
	var min_allowed_zoom := _get_min_fit_zoom()
	var old_zoom := target_zoom
	target_zoom = clampf(target_zoom + zoom_delta, min_allowed_zoom, MAX_ZOOM)
	
	var factor := target_zoom / old_zoom
	var local_pivot := pivot_pos
	if map_viewport:
		local_pivot -= map_viewport.global_position
	target_map_pos = (target_map_pos - local_pivot) * factor + local_pivot
	_clamp_camera_bounds()

func _clamp_camera_bounds() -> void:
	var vp_size: Vector2 = map_viewport.size if map_viewport and map_viewport.size.x > 0 else get_viewport_rect().size
	var scaled_world := WORLD_SIZE * current_zoom
	
	# In-place horizontal clamping: map fills the frame completely with no gaps
	if scaled_world.x >= vp_size.x:
		var min_x := vp_size.x - scaled_world.x
		var max_x := 0.0
		target_map_pos.x = clampf(target_map_pos.x, min_x, max_x)
	else:
		target_map_pos.x = (vp_size.x - scaled_world.x) * 0.5
		
	# In-place vertical clamping: map fills the frame completely with no gaps
	if scaled_world.y >= vp_size.y:
		var min_y := vp_size.y - scaled_world.y
		var max_y := 0.0
		target_map_pos.y = clampf(target_map_pos.y, min_y, max_y)
	else:
		target_map_pos.y = (vp_size.y - scaled_world.y) * 0.5

func _center_camera_on_current_level() -> void:
	var unlocked: int = level_mgr.unlocked_levels if level_mgr else 1
	var target_node_pos := _get_position_for_level(unlocked)
	
	var vp_size: Vector2 = map_viewport.size if map_viewport and map_viewport.size.x > 0 else get_viewport_rect().size
	target_map_pos = (vp_size * 0.5) - (target_node_pos * current_zoom)
	_clamp_camera_bounds()
	map_world.position = target_map_pos

func _spawn_kenney_landmarks() -> void:
	if not landmarks_container:
		return
		
	for child in landmarks_container.get_children():
		child.queue_free()
		
	var tree_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/nature_kit/Isometric/tree_pineTallA_detailed_NE.png"):
		tree_tex = load("res://assets/kenney/nature_kit/Isometric/tree_pineTallA_detailed_NE.png")
		
	# Kenney Hexagon Kit 2D isometric icons
	var castle_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/hexagon_kit/Previews/building-castle.png"):
		castle_tex = load("res://assets/kenney/hexagon_kit/Previews/building-castle.png")
		
	var wizard_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/hexagon_kit/Previews/building-wizard-tower.png"):
		wizard_tex = load("res://assets/kenney/hexagon_kit/Previews/building-wizard-tower.png")
		
	var tower_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/hexagon_kit/Previews/building-tower.png"):
		tower_tex = load("res://assets/kenney/hexagon_kit/Previews/building-tower.png")
		
	var wall_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/hexagon_kit/Previews/building-wall-tower.png"):
		wall_tex = load("res://assets/kenney/hexagon_kit/Previews/building-wall-tower.png")
		
	var smelter_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/hexagon_kit/Previews/building-smelter.png"):
		smelter_tex = load("res://assets/kenney/hexagon_kit/Previews/building-smelter.png")
		
	var village_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/hexagon_kit/Previews/building-village.png"):
		village_tex = load("res://assets/kenney/hexagon_kit/Previews/building-village.png")
		
	# Thematic Landmark Placements using Kenney Hexagon & Nature Kits
	var custom_landmarks: Array[Dictionary] = [
		# Region 1: Whispering Woods
		{"tex": wizard_tex, "pos": Vector2(260, 1080), "size": Vector2(68, 68), "col": Color(1.0, 1.0, 1.0, 0.95)},
		{"tex": village_tex, "pos": Vector2(440, 1210), "size": Vector2(64, 64), "col": Color(1.0, 1.0, 1.0, 0.9)},
		# Region 3: Castle Realm
		{"tex": castle_tex, "pos": Vector2(1040, 740), "size": Vector2(80, 80), "col": Color(1.0, 0.98, 0.95, 0.98)},
		{"tex": wall_tex, "pos": Vector2(920, 780), "size": Vector2(60, 60), "col": Color(0.95, 0.95, 1.0, 0.9)},
		{"tex": wall_tex, "pos": Vector2(1140, 820), "size": Vector2(60, 60), "col": Color(0.95, 0.95, 1.0, 0.9)},
		# Region 4: Underground Dungeon
		{"tex": tower_tex, "pos": Vector2(740, 460), "size": Vector2(56, 56), "col": Color(0.85, 0.85, 0.95, 0.85)},
		{"tex": tower_tex, "pos": Vector2(1040, 460), "size": Vector2(56, 56), "col": Color(0.85, 0.85, 0.95, 0.85)},
		# Region 5: Mire of Sorrows
		{"tex": village_tex, "pos": Vector2(1380, 780), "size": Vector2(60, 60), "col": Color(0.85, 0.95, 0.85, 0.85)},
		# Region 6: Volcanic Firelands
		{"tex": smelter_tex, "pos": Vector2(1660, 410), "size": Vector2(70, 70), "col": Color(1.05, 0.85, 0.7, 0.95)},
		{"tex": smelter_tex, "pos": Vector2(1820, 450), "size": Vector2(64, 64), "col": Color(1.05, 0.85, 0.7, 0.95)},
		# Region 7: Eldritch Spire Citadel
		{"tex": castle_tex, "pos": Vector2(2120, 190), "size": Vector2(88, 88), "col": Color(0.65, 0.6, 0.75, 0.98)},
		{"tex": tower_tex, "pos": Vector2(2240, 160), "size": Vector2(60, 60), "col": Color(0.6, 0.55, 0.7, 0.9)}
	]
	
	for lm in custom_landmarks:
		var tex: Texture2D = lm.get("tex", null)
		if tex:
			var spr := TextureRect.new()
			spr.texture = tex
			spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var sz: Vector2 = lm.get("size", Vector2(64, 64))
			spr.custom_minimum_size = sz
			spr.size = sz
			var pos: Vector2 = lm.get("pos", Vector2.ZERO)
			spr.position = pos - (sz * 0.5)
			spr.mouse_filter = MOUSE_FILTER_IGNORE
			spr.modulate = lm.get("col", Color.WHITE)
			landmarks_container.add_child(spr)
			
	# Pine Trees across Woodlands and mountain foothills
	var tree_coords := [
		Vector2(180, 1110), Vector2(330, 1180), Vector2(510, 1130), Vector2(630, 1220),
		Vector2(880, 1160), Vector2(1010, 1170), Vector2(1130, 1130),
		Vector2(1270, 710), Vector2(1440, 770), Vector2(1590, 710)
	]
	if tree_tex:
		for l_pos in tree_coords:
			var spr := TextureRect.new()
			spr.texture = tree_tex
			spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			spr.custom_minimum_size = Vector2(60, 82)
			spr.size = Vector2(60, 82)
			spr.position = l_pos - Vector2(30, 65)
			spr.mouse_filter = MOUSE_FILTER_IGNORE
			spr.modulate = Color(1.05, 1.05, 1.05, 0.85)
			landmarks_container.add_child(spr)

func _spawn_region_banners() -> void:
	if not region_labels_container:
		return
		
	for child in region_labels_container.get_children():
		child.queue_free()
		
	var panel_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/kenney/fantasy_ui_borders/PNG/Default/Panel/panel-000.png"):
		panel_tex = load("res://assets/kenney/fantasy_ui_borders/PNG/Default/Panel/panel-000.png")
		
	var regions_data := [
		{"name": "🌲 THE WHISPERING WOODS (1-15)", "pos": Vector2(380, 1040)},
		{"name": "⚰️ THE FORGOTTEN GRAVEYARD (16-30)", "pos": Vector2(980, 1030)},
		{"name": "🏰 THE CASTLE REALM (31-45)", "pos": Vector2(880, 620)},
		{"name": "⚔️ THE UNDERGROUND DUNGEON (46-60)", "pos": Vector2(860, 420)},
		{"name": "🌿 THE CURSED WILDERNESS (61-75)", "pos": Vector2(1460, 620)},
		{"name": "🔥 THE VOLCANIC FIRELANDS (76-90)", "pos": Vector2(1740, 320)},
		{"name": "💀 THE ELDRITCH PATH & CITADEL (91-100)", "pos": Vector2(2080, 140)}
	]
	
	for r in regions_data:
		var banner := NinePatchRect.new()
		banner.custom_minimum_size = Vector2(280, 36)
		banner.size = Vector2(280, 36)
		banner.position = r["pos"] - Vector2(140, 18)
		banner.mouse_filter = MOUSE_FILTER_IGNORE
		if panel_tex:
			banner.texture = panel_tex
			banner.patch_margin_left = 16
			banner.patch_margin_top = 16
			banner.patch_margin_right = 16
			banner.patch_margin_bottom = 16
			banner.modulate = Color(1.0, 1.0, 1.0, 0.9)
			
		var lbl := Label.new()
		lbl.set_anchors_preset(PRESET_FULL_RECT)
		lbl.text = r["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_font_size_override("font_size", 12)
		banner.add_child(lbl)
		
		region_labels_container.add_child(banner)

func _get_path_waypoints() -> Array[Vector2]:
	return [
		# Region 1: The Whispering Woods (1-15)
		Vector2(240, 1160), Vector2(360, 1170), Vector2(500, 1160), Vector2(650, 1140),
		# Region 2: The Forgotten Graveyard (16-30)
		Vector2(800, 1120), Vector2(950, 1110), Vector2(1100, 1080), Vector2(1200, 1000),
		# Region 3: The Castle Realm (31-45)
		Vector2(1160, 880), Vector2(1020, 780), Vector2(880, 680), Vector2(780, 600),
		# Region 4: The Underground Dungeon (46-60)
		Vector2(700, 520), Vector2(840, 480), Vector2(980, 500), Vector2(1100, 560),
		# Region 5: The Cursed Wilderness (61-75)
		Vector2(1250, 680), Vector2(1400, 750), Vector2(1540, 740), Vector2(1650, 680),
		# Region 6: The Volcanic Firelands (76-90)
		Vector2(1620, 520), Vector2(1700, 420), Vector2(1820, 380), Vector2(1920, 420),
		# Region 7: The Eldritch Path & Onyx Spire Citadel (91-100)
		Vector2(1980, 360), Vector2(2060, 300), Vector2(2140, 250), Vector2(2200, 210)
	]

func _get_position_for_level(lvl: int) -> Vector2:
	var waypoints := _get_path_waypoints()
	var t: float = float(lvl - 1) / 99.0 * float(waypoints.size() - 1)
	var idx0: int = clampi(int(floor(t)), 0, waypoints.size() - 1)
	var idx1: int = clampi(idx0 + 1, 0, waypoints.size() - 1)
	var frac: float = t - float(idx0)
	var pos: Vector2 = waypoints[idx0].lerp(waypoints[idx1], frac)
	# Organic wave offset
	pos.y += sin(float(lvl) * 0.7) * 5.0
	return pos

func _build_100_level_progression() -> void:
	if not nodes_container:
		return
		
	for child in nodes_container.get_children():
		child.queue_free()
		
	if spark_line_glow:
		spark_line_glow.clear_points()
	if spark_line_core:
		spark_line_core.clear_points()
		
	var unlocked: int = level_mgr.unlocked_levels if level_mgr else 1
	var level_positions: Array[Vector2] = []
	
	# Generate points and Spark Line
	for i in range(1, 101):
		var pos := _get_position_for_level(i)
		level_positions.append(pos)
		if spark_line_glow:
			spark_line_glow.add_point(pos)
		if spark_line_core:
			spark_line_core.add_point(pos)
			
	# Render 100 Level Nodes
	for i in range(1, 101):
		var pos: Vector2 = level_positions[i - 1]
		var is_unlocked: bool = (i <= unlocked)
		var is_current: bool = (i == unlocked)
		var is_completed: bool = (i < unlocked)
		var is_major: bool = (i == 1 or i % 15 == 0 or i == 100)
		var is_final_boss: bool = (i == 100)
		
		var node_size: Vector2
		if is_final_boss:
			node_size = Vector2(64, 64)
		elif is_major:
			node_size = Vector2(50, 50)
		elif i % 5 == 0:
			node_size = Vector2(40, 40)
		else:
			node_size = Vector2(30, 30)
			
		var btn := Button.new()
		btn.custom_minimum_size = node_size
		btn.size = node_size
		btn.position = pos - (node_size * 0.5)
		btn.pivot_offset = node_size * 0.5
		
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = int(node_size.x * 0.5)
		style.corner_radius_top_right = int(node_size.x * 0.5)
		style.corner_radius_bottom_right = int(node_size.x * 0.5)
		style.corner_radius_bottom_left = int(node_size.x * 0.5)
		style.border_width_left = 3 if is_major else 2
		style.border_width_top = 3 if is_major else 2
		style.border_width_right = 3 if is_major else 2
		style.border_width_bottom = 3 if is_major else 2
		
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		btn.add_theme_constant_override("outline_size", 5)
		
		if is_current:
			style.bg_color = Color(1.0, 0.78, 0.15, 0.98)
			style.border_color = Color(1.0, 1.0, 0.7, 1)
			style.shadow_color = Color(1.0, 0.7, 0.1, 0.95)
			style.shadow_size = 18
			btn.text = "👑 %d" % i if is_final_boss else "%d" % i
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			_animate_pulse(btn)
		elif is_completed:
			style.bg_color = Color(0.15, 0.65, 0.35, 0.95)
			style.border_color = Color(0.5, 1.0, 0.65, 1)
			style.shadow_color = Color(0.2, 0.8, 0.4, 0.7)
			style.shadow_size = 8
			btn.text = "%d" % i if (is_major or i % 5 == 0) else ""
			btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
		else:
			# Locked level state
			style.bg_color = Color(0.18, 0.14, 0.25, 0.9)
			style.border_color = Color(0.42, 0.35, 0.52, 1)
			style.shadow_color = Color(0.1, 0.05, 0.15, 0.6)
			style.shadow_size = 4
			btn.text = "%d" % i if (is_major or i % 5 == 0) else ""
			btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.9))
			
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_font_size_override("font_size", 14 if is_major else 11)
		
		btn.mouse_entered.connect(func():
			var tween := create_tween()
			tween.tween_property(btn, "scale", Vector2(1.25, 1.25), 0.1)
		)
		btn.mouse_exited.connect(func():
			var tween := create_tween()
			tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
		)
		
		var lvl_index := i
		var btn_press_start := Vector2.ZERO
		btn.button_down.connect(func():
			btn_press_start = get_viewport().get_mouse_position()
			btn_drag_moved = false
		)
		btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton:
				var mb := ev as InputEventMouseButton
				if mb.button_index == MOUSE_BUTTON_RIGHT:
					if mb.pressed:
						is_dragging = true
						drag_moved = false
						btn_drag_moved = false
						btn_press_start = get_viewport().get_mouse_position()
						drag_world_start = target_map_pos
						_set_drag_cursor(true)
					else:
						is_dragging = false
						_set_drag_cursor(false)
			elif ev is InputEventMouseMotion and (is_dragging or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
				if (get_viewport().get_mouse_position() - btn_press_start).length() > 4.0:
					btn_drag_moved = true
					drag_moved = true
					is_dragging = true
					_set_drag_cursor(true)
					target_map_pos += (ev as InputEventMouseMotion).relative
					_clamp_camera_bounds()
					map_world.position = target_map_pos
		)
		btn.pressed.connect(func():
			if not btn_drag_moved and not drag_moved:
				_on_level_node_pressed(lvl_index)
		)
		nodes_container.add_child(btn)

func _animate_pulse(btn: Button) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(btn, "scale", Vector2(1.18, 1.18), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_level_node_pressed(lvl: int) -> void:
	var unlocked: int = level_mgr.unlocked_levels if level_mgr else 1
	if lvl > unlocked:
		_show_locked_toast(lvl, unlocked)
	else:
		_open_level_modal(lvl)

func _show_locked_toast(lvl: int, unlocked: int) -> void:
	if not toast_panel or not toast_label:
		return
		
	toast_label.text = "🔒 Complete Level %d to unlock Level %d." % [lvl - 1, lvl]
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.scale = Vector2(0.8, 0.8)
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween()
	toast_tween.set_parallel(true)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	toast_tween.chain().tween_interval(2.2)
	toast_tween.chain().tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.chain().tween_callback(func(): toast_panel.visible = false)

func _open_level_modal(lvl: int) -> void:
	selected_level_num = lvl
	var cfg: Dictionary = level_mgr.get_level_config(lvl) if level_mgr else {}
	var ch_idx: int = level_mgr.get_chapter_for_level(lvl) if (level_mgr and level_mgr.has_method("get_chapter_for_level")) else 1
	var ch_data: Dictionary = level_mgr.CHAPTER_MAPS.get(ch_idx, {}) if (level_mgr and "CHAPTER_MAPS" in level_mgr) else {}
	var map_name: String = str(ch_data.get("name", "Realm"))
	var boss_title: String = str(ch_data.get("boss_name", "Boss"))
	var is_boss_lvl: bool = (lvl % 10 == 0)
	
	if level_title_label:
		level_title_label.text = "LEVEL %d: %s" % [lvl, map_name.to_upper()]
	if region_name_label:
		region_name_label.text = "👑 BOSS STAGE: %s" % boss_title if is_boss_lvl else "🗺️ REALM: %s (%s)" % [map_name, ch_data.get("region", "")]
	if difficulty_label:
		var stars_count: int = cfg.get("difficulty_stars", 1)
		var star_str := ""
		for s in range(stars_count): star_str += "⭐"
		difficulty_label.text = "DIFFICULTY: %s" % star_str
	if objective_label:
		if is_boss_lvl:
			objective_label.text = "OBJECTIVE:\nDefeat %s in an epic chapter showdown!" % boss_title
		else:
			objective_label.text = "OBJECTIVE:\nDefeat %d arena combatants and survive the realm storm!" % cfg.get("enemy_count", 15)
	if reward_label:
		reward_label.text = "REWARDS:\n🪙 %d Coins  |  ⭐ %d XP" % [cfg.get("reward_coins", 300), cfg.get("reward_xp", 150)]
		
	if start_btn:
		if is_boss_lvl:
			start_btn.text = "👑 FIGHT BOSS: %s" % boss_title
		else:
			start_btn.text = "⚔️ PLAY LEVEL %d BATTLE" % lvl
			
	var boss_btn := modal_card.find_child("BossDuelBtn", true, false) as Button
	if not boss_btn:
		boss_btn = Button.new()
		boss_btn.name = "BossDuelBtn"
		boss_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.8, 0.22, 0.18)
		sb.set_border_width_all(2)
		sb.border_color = Color(1.0, 0.8, 0.3)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		boss_btn.add_theme_stylebox_override("normal", sb)
		boss_btn.add_theme_color_override("font_color", Color.WHITE)
		boss_btn.add_theme_font_size_override("font_size", 13)
		start_btn.get_parent().add_child(boss_btn)
		
	boss_btn.text = "👑 TEST CHAPTER BOSS (%s)" % boss_title
	boss_btn.visible = not is_boss_lvl
	if boss_btn.pressed.is_connected(_on_start_boss_duel):
		boss_btn.pressed.disconnect(_on_start_boss_duel)
	boss_btn.pressed.connect(_on_start_boss_duel)
		
	if modal_panel:
		modal_panel.visible = true
		modal_panel.mouse_filter = MOUSE_FILTER_STOP
		modal_panel.modulate.a = 0.0
		if modal_card:
			modal_card.scale = Vector2(0.85, 0.85)
			var tween := create_tween().set_parallel(true)
			tween.tween_property(modal_panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(modal_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_level_modal() -> void:
	if not modal_panel or not modal_panel.visible:
		return
	if modal_card:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(modal_panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(modal_card, "scale", Vector2(0.85, 0.85), 0.15)
		await tween.finished
	modal_panel.visible = false
	modal_panel.mouse_filter = MOUSE_FILTER_IGNORE

func _on_start_selected_level() -> void:
	if level_mgr:
		level_mgr.current_level_id = selected_level_num
		level_mgr.is_boss_encounter_mode = (selected_level_num % 10 == 0)
		if level_mgr.has_method("get_level_scene_path"):
			level_mgr.selected_map_scene_path = level_mgr.get_level_scene_path(selected_level_num)
	level_selected.emit(selected_level_num)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/ui/matchmaking_screen.tscn")
	)

func _on_start_boss_duel() -> void:
	if level_mgr:
		level_mgr.current_level_id = selected_level_num
		level_mgr.is_boss_encounter_mode = true
		if level_mgr.has_method("get_level_scene_path"):
			level_mgr.selected_map_scene_path = level_mgr.get_level_scene_path(selected_level_num)
	level_selected.emit(selected_level_num)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/ui/matchmaking_screen.tscn")
	)

func _update_current_region_hud() -> void:
	if not region_label:
		return
		
	var vp_size := get_viewport_rect().size
	var center_world_pos := (-map_world.position + (vp_size * 0.5)) / current_zoom
	
	var reg_text := "🌲 REGION 1: THE WHISPERING WOODS (1-15)"
	if center_world_pos.x > 1880:
		reg_text = "💀 REGION 7: THE ELDRITCH PATH (91-100)"
	elif center_world_pos.x > 1580:
		reg_text = "🔥 REGION 6: THE VOLCANIC FIRELANDS (76-90)"
	elif center_world_pos.x > 1240:
		reg_text = "🌿 REGION 5: THE CURSED WILDERNESS (61-75)"
	elif center_world_pos.x > 940:
		reg_text = "⚔️ REGION 4: THE UNDERGROUND DUNGEON (46-60)"
	elif center_world_pos.x > 680:
		reg_text = "🏰 REGION 3: THE CASTLE REALM (31-45)"
	elif center_world_pos.x > 450:
		reg_text = "⚰️ REGION 2: THE FORGOTTEN GRAVEYARD (16-30)"
		
	region_label.text = reg_text

func _update_topbar_currencies() -> void:
	if level_mgr:
		if coins_label:
			coins_label.text = "🪙 %d" % level_mgr.player_coins
		if gems_label:
			gems_label.text = "💎 %d" % level_mgr.player_gems

func _animate_ui_entry() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)

func _on_return_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
