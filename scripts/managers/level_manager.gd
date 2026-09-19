class_name LevelManager
extends Node

## LudusForge 100-Level Manager & Save System
## Manages level configurations, difficulty scaling, save/load persistence,
## and level progression.

static var _instance: LevelManager = null
static var instance: LevelManager:
	get:
		if _instance == null:
			_instance = LevelManager.new()
		return _instance
	set(val):
		_instance = val

static func get_instance() -> LevelManager:
	return instance

var unlocked_levels: int = 1
var current_level_id: int = 1
var player_coins: int = 1126
var player_gems: int = 0
var player_xp: int = 120

var selected_hero_id: String = "dragonbound"
var selected_map_scene_path: String = ""

const PLAYABLE_CHARACTERS := {
	"dragonbound": {
		"id": "dragonbound",
		"name": "Dragonbound",
		"class": "Infernal Pyromancer",
		"title": "Draconic Overlord",
		"scene_path": "res://characters/dragonbound/dragonbound_character.tscn",
		"icon": "🐉",
		"desc": "Active multi-axis 3D flapping wings, hovering flight, infernal dash, and magma breath.",
		"stats": "ATK: 105  •  HP: 600  •  SPD: 5.6",
		"passive": "+25% Fire AoE & Hovering Flight",
		"color": Color(1.0, 0.5, 0.15),
		"rim_color": Color(0.95, 0.2, 0.1)
	},
	"celestial": {
		"id": "celestial",
		"name": "Celestial Seraph",
		"class": "Heavenly Ascendant",
		"title": "Archangel of Retribution",
		"scene_path": "res://characters/celestial/celestial_character.tscn",
		"icon": "✨",
		"desc": "Divine golden halo, quad seraph wings, celestial beam cannon, and radiant barrier.",
		"stats": "ATK: 98  •  HP: 550  •  SPD: 5.4",
		"passive": "Divine Light Aura & Invulnerable Dash",
		"color": Color(1.0, 0.88, 0.4),
		"rim_color": Color(0.3, 0.85, 1.0)
	},
	"arcane_apprentice": {
		"id": "arcane_apprentice",
		"name": "Arcane Apprentice",
		"class": "Storm Magus",
		"title": "Lightning Adept",
		"scene_path": "res://characters/arcane_apprentice/apprentice_character.tscn",
		"icon": "⚡",
		"desc": "Celtic lightning wand, high-voltage electro blast, spark dash, and kinetic barriers.",
		"stats": "ATK: 90  •  HP: 480  •  SPD: 5.8",
		"passive": "+20% Attack Speed & Electric Stun",
		"color": Color(0.4, 0.9, 1.0),
		"rim_color": Color(0.75, 0.25, 0.95)
	},
	"pyromancer": {
		"id": "pyromancer",
		"name": "Classic Magus",
		"class": "Elemental Sorcerer",
		"title": "Flame Magus",
		"scene_path": "res://scenes/player/player.tscn",
		"icon": "🧙‍♂️",
		"desc": "Original battle arena sorcerer wielding explosive fireballs and freezing ice lances.",
		"stats": "ATK: 92  •  HP: 500  •  SPD: 5.2",
		"passive": "Dual Element Mastery (Fire & Ice)",
		"color": Color(0.95, 0.35, 0.15),
		"rim_color": Color(1.0, 0.75, 0.2)
	}
}

const CHAPTER_MAPS := {
	1: {
		"id": 1,
		"chapter_key": "chapter_01",
		"name": "Emerald Plains",
		"region": "The Whispering Woods",
		"level_range": "1 - 10",
		"scene_path": "res://scenes/maps/emerald_plains/emerald_plains.tscn",
		"boss_name": "Gorgon — The Treant King",
		"icon": "🌲",
		"desc": "Lush woodland clearing guarded by ancient roots, treants, and living forest storms."
	},
	2: {
		"id": 2,
		"chapter_key": "chapter_02",
		"name": "Desert Mirage",
		"region": "The Sunken Sands",
		"level_range": "11 - 20",
		"scene_path": "res://scenes/maps/chapter_02_desert_mirage/desert_mirage.tscn",
		"boss_name": "Anubis — Scythe Lord of Dunes",
		"icon": "🏜️",
		"desc": "Blistering dunes, ancient pharaonic stone monoliths, and sweeping sandstorms."
	},
	3: {
		"id": 3,
		"chapter_key": "chapter_03",
		"name": "Frostbite Tundra",
		"region": "The Glacial Peaks",
		"level_range": "21 - 30",
		"scene_path": "res://scenes/maps/chapter_03_frostbite_tundra/frostbite_tundra.tscn",
		"boss_name": "Ymir — Glacial Berserker",
		"icon": "❄️",
		"desc": "Sub-zero ice shelf flanked by jagged glaciers, frost crystals, and frozen blizzards."
	},
	4: {
		"id": 4,
		"chapter_key": "chapter_04",
		"name": "Magma Core",
		"region": "The Volcanic Firelands",
		"level_range": "31 - 40",
		"scene_path": "res://scenes/maps/chapter_04_magma_core/magma_core.tscn",
		"boss_name": "Ignis — Molten Overlord",
		"icon": "🌋",
		"desc": "Molten caldera surrounded by boiling lava rivers, volcanic eruptions, and obsidian rock."
	},
	5: {
		"id": 5,
		"chapter_key": "chapter_05",
		"name": "Mystic Grove",
		"region": "The Bioluminescent Hollows",
		"level_range": "41 - 50",
		"scene_path": "res://scenes/maps/chapter_05_mystic_grove/mystic_grove.tscn",
		"boss_name": "Nightshade — Spore Queen",
		"icon": "🍄",
		"desc": "Deep twilight forest dense with giant luminescent mushrooms and toxic fungal spores."
	},
	6: {
		"id": 6,
		"chapter_key": "chapter_06",
		"name": "Castle Ruins",
		"region": "The Fortress Bastion",
		"level_range": "51 - 60",
		"scene_path": "res://scenes/maps/chapter_06_castle_ruins/castle_ruins.tscn",
		"boss_name": "Warlord Iron-Bane",
		"icon": "🏰",
		"desc": "Shattered medieval stone ramparts, battlements, ballistas, and ruined iron siege gates."
	},
	7: {
		"id": 7,
		"chapter_key": "chapter_07",
		"name": "Pirate Cove",
		"region": "The Scourge Shores",
		"level_range": "61 - 70",
		"scene_path": "res://scenes/maps/chapter_07_pirate_cove/pirate_cove.tscn",
		"boss_name": "Captain Davy Blood-Tide",
		"icon": "🏴‍☠️",
		"desc": "Shipwreck bay lined with beached galleons, wooden piers, cannons, and pirate skulls."
	},
	8: {
		"id": 8,
		"chapter_key": "chapter_08",
		"name": "Cursed Swamp",
		"region": "The Forgotten Graveyard",
		"level_range": "71 - 80",
		"scene_path": "res://scenes/maps/chapter_08_cursed_swamp/cursed_swamp.tscn",
		"boss_name": "Lord Malakor — High Necromancer",
		"icon": "💀",
		"desc": "Dark stagnant waters, rotting logs, mossy tombstones, and necromantic crypt lanterns."
	},
	9: {
		"id": 9,
		"chapter_key": "chapter_09",
		"name": "Cosmic Void",
		"region": "The Astral Expanse",
		"level_range": "81 - 90",
		"scene_path": "res://scenes/maps/chapter_09_cosmic_void/cosmic_void.tscn",
		"boss_name": "Xeno-Gorgon Apex",
		"icon": "🌌",
		"desc": "Sci-fi space station platform surrounded by asteroid clusters, void crystals, and nebula light."
	},
	10: {
		"id": 10,
		"chapter_key": "chapter_10",
		"name": "Celestial Peak",
		"region": "The Eldritch Path (Divine Realm)",
		"level_range": "91 - 100",
		"scene_path": "res://scenes/maps/chapter_10_celestial_peak/celestial_peak.tscn",
		"boss_name": "Judgment Seraph",
		"icon": "👑",
		"desc": "Floating summit temple above the clouds featuring divine marble pillars and golden obelisks."
	},
	0: {
		"id": 0,
		"chapter_key": "arena",
		"name": "Gladiator Arena",
		"region": "Free For All Battle Royale",
		"level_range": "FFA",
		"scene_path": "res://scenes/arena/arena.tscn",
		"boss_name": "15-Player Free For All",
		"icon": "⚔️",
		"desc": "Classic circular battle royale colosseum with 15 combatants and closing electric storm."
	}
}

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

func _enter_tree() -> void:
	instance = self

func _generate_100_levels() -> void:
	for i in range(1, 101):
		var reg: Dictionary = get_region_for_level(i)
		var r_name: String = reg.get("name", "Eldritch Path")
		var lname: String = "%s Stage %d" % [r_name, i]
		if i == 100:
			lname = "Skull Dragon Citadel (Grand Final Boss)"
			
		var difficulty_stars: int = clampi(1 + int(float(i - 1) / 33.0), 1, 3)
		var diff: Dictionary = scale_difficulty(i)
		levels[i] = {
			"id": i,
			"name": lname,
			"difficulty_stars": difficulty_stars,
			"enemy_count": diff.get("enemy_count", 14),
			"reward_xp": diff.get("reward_xp", 100 + i * 50),
			"reward_coins": diff.get("reward_coins", 300 + i * 100),
			"region_name": r_name,
			"region_id": reg.get("id", 1),
			"region_color": reg.get("color", Color.WHITE)
		}

func get_level_config(level_id: int) -> Dictionary:
	if levels.has(level_id):
		return levels[level_id]
	return levels[1]

func scale_difficulty(level_num: int) -> Dictionary:
	var lvl: int = maxi(1, level_num)
	var lvl_factor: float = float(lvl - 1)
	
	# Progressive bot count: Level 1: 14, Level 2: 16, Level 3: 17, Level 5: 20...
	var count: int = clampi(14 + int(lvl_factor * 1.5), 14, 35)
	
	# Progressive health: +15% per level (Level 1: 1.0x, Level 2: 1.15x, Level 3: 1.30x...)
	var hp_mult: float = 1.0 + (lvl_factor * 0.15)
	
	# Progressive speed: +3.5% per level, up to 1.45x
	var spd_mult: float = clampf(1.0 + (lvl_factor * 0.035), 1.0, 1.45)
	
	# Progressive bot aggression/attack rate: cooldown reduces slightly
	var cd_mult: float = clampf(1.0 - (lvl_factor * 0.025), 0.65, 1.0)
	
	return {
		"enemy_count": count,
		"health_multiplier": hp_mult,
		"speed_multiplier": spd_mult,
		"cooldown_multiplier": cd_mult,
		"enemy_health": 100.0 * hp_mult,
		"enemy_speed": 4.4 * spd_mult,
		"reward_xp": 100 + lvl * 50,
		"reward_coins": 300 + lvl * 100
	}

func unlock_next_level() -> void:
	var next_lvl: int = current_level_id + 1
	if next_lvl > unlocked_levels:
		unlocked_levels = mini(100, next_lvl)
	var cfg := get_level_config(current_level_id)
	player_coins += cfg.get("reward_coins", 300)
	player_xp += cfg.get("reward_xp", 100)
	current_level_id = mini(100, next_lvl)
	save_progression()

func get_selected_player_scene() -> PackedScene:
	if PLAYABLE_CHARACTERS.has(selected_hero_id):
		var path: String = PLAYABLE_CHARACTERS[selected_hero_id].get("scene_path", "")
		if ResourceLoader.exists(path):
			var sc := load(path) as PackedScene
			if sc:
				return sc
	# Default fallback
	var fallback := "res://characters/dragonbound/dragonbound_character.tscn"
	if ResourceLoader.exists(fallback):
		return load(fallback) as PackedScene
	return load("res://scenes/player/player.tscn") as PackedScene

func get_chapter_for_level(lvl: int) -> int:
	if lvl <= 10: return 1
	elif lvl <= 20: return 2
	elif lvl <= 30: return 3
	elif lvl <= 40: return 4
	elif lvl <= 50: return 5
	elif lvl <= 60: return 6
	elif lvl <= 70: return 7
	elif lvl <= 80: return 8
	elif lvl <= 90: return 9
	else: return 10

func get_level_scene_path(lvl: int) -> String:
	var ch: int = get_chapter_for_level(lvl)
	if CHAPTER_MAPS.has(ch):
		var p: String = CHAPTER_MAPS[ch].get("scene_path", "")
		if ResourceLoader.exists(p):
			return p
	return "res://scenes/arena/arena.tscn"

func get_active_gameplay_scene() -> String:
	if selected_map_scene_path != "" and ResourceLoader.exists(selected_map_scene_path):
		return selected_map_scene_path
	return get_level_scene_path(current_level_id)

var is_boss_encounter_mode: bool = false

func should_spawn_boss(lvl: int) -> bool:
	if is_boss_encounter_mode:
		return true
	return (lvl > 0 and lvl % 10 == 0)

func save_progression() -> void:
	var data := {
		"unlocked_levels": unlocked_levels,
		"current_level_id": current_level_id,
		"player_coins": player_coins,
		"player_gems": player_gems,
		"player_xp": player_xp,
		"selected_hero_id": selected_hero_id,
		"selected_map_scene_path": selected_map_scene_path
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
			if dict.has("selected_hero_id"):
				selected_hero_id = str(dict.get("selected_hero_id", selected_hero_id))
			if dict.has("selected_map_scene_path"):
				selected_map_scene_path = str(dict.get("selected_map_scene_path", selected_map_scene_path))
