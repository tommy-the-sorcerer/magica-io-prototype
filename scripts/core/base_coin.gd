class_name BaseCoin
extends Area3D

## Reusable Collectible Coin with continuous rotation, sinusoidal bobbing, and player magnetism

@export var coin_value: int = 1
@export var rotation_speed: float = 3.0
@export var bob_amplitude: float = 0.12
@export var bob_frequency: float = 4.0
@export var magnet_range: float = 4.5
@export var magnet_speed: float = 12.0

var base_y: float = 0.5
var target_player: Node3D = null
var is_collected: bool = false
var time_offset: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	add_to_group("collectibles")
	add_to_group("coins")
	base_y = position.y
	time_offset = randf_range(0.0, 10.0)
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
		
	# Constant rotation
	if mesh:
		mesh.rotation.y += rotation_speed * delta
		
	# Check for player in magnet range
	if not target_player:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty() and is_instance_valid(players[0]):
			var p: Node3D = players[0] as Node3D
			if global_position.distance_to(p.global_position) <= magnet_range:
				target_player = p

	if target_player and is_instance_valid(target_player):
		# Magnetically accelerate toward player
		var dir := (target_player.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
		global_position += dir * magnet_speed * delta
		if global_position.distance_to(target_player.global_position) < 0.9:
			_collect(target_player)
	else:
		# Idle bobbing
		position.y = base_y + sin((Time.get_ticks_msec() * 0.001 * bob_frequency) + time_offset) * bob_amplitude

func _on_body_entered(body: Node) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		_collect(body)

func _collect(collector: Node) -> void:
	if is_collected:
		return
	is_collected = true
	
	# Update HUD token counter if available
	var hud := get_tree().current_scene.find_child("HUD", true, false)
	if hud:
		var tokens_label: Label = hud.find_child("TokensLabel", true, false) as Label
		if tokens_label:
			var current_str: String = tokens_label.text.replace("🪙", "").replace("COINS:", "").strip_edges()
			var current_val: int = int(current_str)
			current_val += coin_value
			tokens_label.text = "🪙 %d" % current_val
			
	# Scale burst and destroy
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.08)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.08)
	tween.tween_callback(queue_free)
