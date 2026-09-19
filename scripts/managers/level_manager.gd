class_name LevelManager
extends Node

## LudusForge 100-Level Manager & Save System
## Manages level configurations, difficulty scaling, save/load persistence,
## and level progression.

static var instance: LevelManager = null

var unlocked_levels: int = 1
var current_level_id: int = 1
var player_coins: int = 1126
var player_gems: int = 0
var player_xp: int = 120

const SAVE_PATH: String = "user://ludusforge_save.json"

const REGIONS = [
	{"id": 1, "range": "1-15", "name": "The Whispering Woods", "desc": "Beginner Kingdom & Woodlands", "color": Color(0.2, 0.75, 0.35)},
	{"id": 2, "range": "16-30", "name": "The Forgotten Graveyard", "desc": "Ancient Crypts & Cursed Tombstones", "color": Color(0.45, 0.35, 0.65)},
	{"id": 3, "range": "31-45", "name": "The Castle Realm", "desc": "High Fortress & Mountain Keep", "color": Color(0.85, 0.7, 0.25)},
	{"id": 4, "range": "46-60", "name": "The Underground Dungeon", "desc": "Dangerous Caverns & Stone Ruins", "color": Color(0.35, 0.65, 0.85)},
	{"id": 5, "range": "61-75", "name": "The Wilderness & Marshes", "desc": "Magical Green Wetlands & Shrines", "color": Color(0.25, 0.8, 0.55)},
	{"id": 6, "range": "76-90", "name": "The Volcanic Firelands", "desc": "Molten Rivers & Corrupted Castles", "color": Color(0.95, 0.45, 0.15)},
	{"id": 7, "range": "91-100", "name": "The Eldritch Path", "desc": "Skull Dragon Citadel & Final Domain", "color": Color(0.85, 0.2, 0.3)}
]

var levels: Dictionary = {}

func _init() -> void:
	instance = self
	_generate_100_levels()
	load_progression()

func get_region_for_level(level_id: int) -> Dictionary:
	if level_id <= 15: return REGIONS[0]
	elif level_id <= 30: return REGIONS[1]
	elif level_id <= 45: return REGIONS[2]
	elif level_id <= 60: return REGIONS[3]
	elif level_id <= 75: return REGIONS[4]
	elif level_id <= 90: return REGIONS[5]
	else: return REGIONS[6]

func _generate_100_levels() -> void:
	for i in range(1, 101):
		var reg: Dictionary = get_region_for_level(i)
		var r_name: String = reg.get("name", "Eldritch Path")
		var lname: String = "%s Stage %d" % [r_name, i]
		if i == 100:
			lname = "Skull Dragon Citadel (Grand Final Boss)"
			
		var difficulty_stars: int = clampi(1 + int(float(i - 1) / 33.0), 1, 3)
		levels[i] = {
			"id": i,
			"name": lname,
			"difficulty_stars": difficulty_stars,
			"enemy_count": mini(50, 4 + i),
			"reward_xp": 100 + i * 45,
			"reward_coins": 300 + i * 80,
			"region_name": r_name,
			"region_id": reg.get("id", 1),
			"region_color": reg.get("color", Color.WHITE)
		}

func get_level_config(level_id: int) -> Dictionary:
	if levels.has(level_id):
		return levels[level_id]
	return levels[1]

func scale_difficulty(level_num: int) -> Dictionary:
	return {
		"enemy_health": 100.0 * (1.0 + level_num * 0.05),
		"enemy_speed": 4.5 * (1.0 + level_num * 0.03),
		"spawn_rate": maxf(1.0 - level_num * 0.005, 0.3)
	}

func unlock_next_level() -> void:
	if current_level_id >= unlocked_levels:
		unlocked_levels = mini(100, current_level_id + 1)
	var cfg := get_level_config(current_level_id)
	player_coins += cfg.get("reward_coins", 300)
	player_xp += cfg.get("reward_xp", 100)
	save_progression()

func save_progression() -> void:
	var data := {
		"unlocked_levels": unlocked_levels,
		"current_level_id": current_level_id,
		"player_coins": player_coins,
		"player_gems": player_gems,
		"player_xp": player_xp
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_progression() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		file.close()
		var json := JSON.new()
		if json.parse(json_text) == OK and json.data is Dictionary:
			var dict: Dictionary = json.data
			unlocked_levels = int(dict.get("unlocked_levels", 1))
			current_level_id = int(dict.get("current_level_id", 1))
			player_coins = int(dict.get("player_coins", 1126))
			player_gems = int(dict.get("player_gems", 0))
			player_xp = int(dict.get("player_xp", 120))
