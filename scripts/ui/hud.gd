class_name HUD
extends CanvasLayer

## Mobile In-Game HUD with Alive Counter, Dynamic Kill Feed, and Victory/Defeat Overlays

@onready var alive_label: Label = $TopBar/LeftInfo/AliveLabel
@onready var kills_label: Label = $TopBar/LeftInfo/KillsLabel
@onready var kill_feed_container: VBoxContainer = $TopBar/KillFeedContainer

@onready var hp_bar: ProgressBar = $BottomBar/HPContainer/HPBar
@onready var hp_label: Label = $BottomBar/HPContainer/HPLabel
@onready var level_label: Label = $BottomBar/LevelContainer/LevelLabel
@onready var xp_bar: ProgressBar = $BottomBar/LevelContainer/XPBar

@onready var victory_panel: Control = $EndGameOverlay/VictoryPanel
@onready var defeat_panel: Control = $EndGameOverlay/DefeatPanel
@onready var rank_label: Label = $EndGameOverlay/DefeatPanel/RankLabel
@onready var restart_button_vic: Button = $EndGameOverlay/VictoryPanel/RestartButton
@onready var restart_button_def: Button = $EndGameOverlay/DefeatPanel/RestartButton

var current_kills: int = 0

func _ready() -> void:
	victory_panel.visible = false
	defeat_panel.visible = false
	restart_button_vic.pressed.connect(_on_restart_pressed)
	restart_button_def.pressed.connect(_on_restart_pressed)

func update_alive_count(alive: int, total: int = 15) -> void:
	alive_label.text = "👤 Alive: %d / %d" % [alive, total]

func add_kill() -> void:
	current_kills += 1
	kills_label.text = "⚔️ Kills: %d" % current_kills

func update_player_hp(curr: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = curr
	hp_label.text = "%d / %d" % [int(curr), int(max_hp)]

func update_player_xp(curr_xp: float, max_xp: float, level: int) -> void:
	level_label.text = "Lv. %d" % level
	xp_bar.max_value = max_xp
	xp_bar.value = curr_xp

func add_kill_feed(killer_name: String, victim_name: String, is_player_killer: bool) -> void:
	var label := Label.new()
	label.theme_override_font_sizes/font_size = 14
	
	if is_player_killer:
		label.text = "👑 YOU 💥 %s" % victim_name
		label.modulate = Color(1.0, 0.85, 0.2) # Gold
	else:
		label.text = "%s 💥 %s" % [killer_name, victim_name]
		label.modulate = Color(0.9, 0.9, 0.9, 0.85)
		
	kill_feed_container.add_child(label)
	
	# Auto fade-out and free after 3.5 seconds
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func show_victory() -> void:
	victory_panel.visible = true
	var tween := create_tween()
	victory_panel.modulate.a = 0.0
	tween.tween_property(victory_panel, "modulate:a", 1.0, 0.5)

func show_defeat(final_rank: int) -> void:
	rank_label.text = "RANK #%d" % final_rank
	defeat_panel.visible = true
	var tween := create_tween()
	defeat_panel.modulate.a = 0.0
	tween.tween_property(defeat_panel, "modulate:a", 1.0, 0.5)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
