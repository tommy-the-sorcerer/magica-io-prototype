extends Control

## Fake 3-second mobile matchmaking screen simulating online 15-player battle royale
signal match_found

@onready var status_label: Label = $VBox/StatusLabel
@onready var count_label: Label = $VBox/CountLabel
@onready var ping_label: Label = $TopBar/PingLabel
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var start_button: Button = $VBox/StartButton if has_node("VBox/StartButton") else null

var current_players: int = 1
var target_players: int = 15
var is_searching: bool = true

func _ready() -> void:
	if LevelManager.instance:
		var diff: Dictionary = LevelManager.instance.scale_difficulty(LevelManager.instance.current_level_id)
		target_players = diff.get("enemy_count", 14) + 1
	if progress_bar:
		progress_bar.max_value = target_players
	# Randomize simulated ping
	var ping: int = randi_range(18, 42)
	ping_label.text = "🟢 Global Server | %d ms" % ping
	_simulate_queue()

func _simulate_queue() -> void:
	status_label.text = "SEARCHING FOR OPPONENTS..."
	count_label.text = "1 / %d Players" % target_players
	progress_bar.value = 1
	
	# Rapidly simulate players joining the room
	var timer := get_tree().create_timer(0.4)
	timer.timeout.connect(_add_random_player)

func _add_random_player() -> void:
	if not is_searching:
		return
		
	var batch: int = randi_range(2, 4)
	current_players = mini(target_players, current_players + batch)
	count_label.text = "%d / %d Players" % [current_players, target_players]
	progress_bar.value = current_players
	
	if current_players < target_players:
		var delay: float = randf_range(0.3, 0.7)
		get_tree().create_timer(delay).timeout.connect(_add_random_player)
	else:
		_on_all_players_found()

func _on_all_players_found() -> void:
	is_searching = false
	status_label.text = "MATCH FOUND! STARTING BATTLE..."
	count_label.text = "%d / %d Players Ready!" % [target_players, target_players]
	
	# Quick countdown
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func(): status_label.text = "Starting in 3...")
	tween.tween_interval(0.8)
	tween.tween_callback(func(): status_label.text = "Starting in 2...")
	tween.tween_interval(0.8)
	tween.tween_callback(func(): status_label.text = "Starting in 1...")
	tween.tween_interval(0.6)
	tween.tween_callback(_start_game)

func _start_game() -> void:
	match_found.emit()
	var target_scene := "res://scenes/arena/arena.tscn"
	if LevelManager.instance and LevelManager.instance.has_method("get_active_gameplay_scene"):
		target_scene = LevelManager.instance.get_active_gameplay_scene()
	
	# Smooth fade out and transition to gameplay scene
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(target_scene)
	)
