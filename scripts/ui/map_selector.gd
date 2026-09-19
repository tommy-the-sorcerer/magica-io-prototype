extends Control

## Map / Chapter Selector Menu for Magica.io
## Allows players, teammates, and evaluators to instantly launch and play any of the 10 maps.

const MAPS = [
	{ "chapter": 1, "name": "Emerald Plains", "theme": "Floating Sky Island & Waterfall Abyss", "path": "res://scenes/maps/emerald_plains/emerald_plains.tscn", "icon": "🌲" },
	{ "chapter": 2, "name": "Desert Mirage", "theme": "Sun-Drenched Oasis & Quicksand", "path": "res://scenes/maps/chapter_02_desert_mirage/desert_mirage.tscn", "icon": "🏜️" },
	{ "chapter": 3, "name": "Frostbite Tundra", "theme": "Glacial Ice Spire Chasm", "path": "res://scenes/maps/chapter_03_frostbite_tundra/frostbite_tundra.tscn", "icon": "❄️" },
	{ "chapter": 4, "name": "Magma Core", "theme": "Active Volcano with Parabolic Lava Arcs", "path": "res://scenes/maps/chapter_04_magma_core/magma_core.tscn", "icon": "🌋" },
	{ "chapter": 5, "name": "Mystic Grove", "theme": "Enchanted Glowing Mushroom Forest", "path": "res://scenes/maps/chapter_05_mystic_grove/mystic_grove.tscn", "icon": "🍄" },
	{ "chapter": 6, "name": "Castle Ruins", "theme": "Fortified Citadel, Towers & Catapults", "path": "res://scenes/maps/chapter_06_castle_ruins/castle_ruins.tscn", "icon": "🏰" },
	{ "chapter": 7, "name": "Pirate Cove", "theme": "Wrecked Galleon, Cannons & Gold Chests", "path": "res://scenes/maps/chapter_07_pirate_cove/pirate_cove.tscn", "icon": "🏴‍☠️" },
	{ "chapter": 8, "name": "Cursed Swamp", "theme": "Gothic Crypts, Gravestones & Iron Fences", "path": "res://scenes/maps/chapter_08_cursed_swamp/cursed_swamp.tscn", "icon": "🪦" },
	{ "chapter": 9, "name": "Cosmic Void", "theme": "3D Starfield, Antennas & Space Speeders", "path": "res://scenes/maps/chapter_09_cosmic_void/cosmic_void.tscn", "icon": "🚀" },
	{ "chapter": 10, "name": "Celestial Peak", "theme": "Divine Temple Pillars & Rune Rings", "path": "res://scenes/maps/chapter_10_celestial_peak/celestial_peak.tscn", "icon": "🏛️" }
]

@onready var grid_container: GridContainer = $CenterContainer/VBoxContainer/ScrollContainer/GridContainer

func _ready() -> void:
	for m in MAPS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 85)
		btn.text = "%s Chapter %d: %s\n%s" % [m["icon"], m["chapter"], m["name"], m["theme"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Styling button
		btn.add_theme_font_size_override("font_size", 14)
		var map_path: String = m["path"]
		btn.pressed.connect(func(): _load_map(map_path))
		grid_container.add_child(btn)

func _load_map(path: String) -> void:
	get_tree().change_scene_to_file(path)
