class_name WorldManager
extends Node

## Manages 10 Distinct Themed Battle Worlds with tuned contrast, dark backgrounds, and soft lighting
## Specifically balanced so the white-and-gold Seraph hero, floating halo, wings, and spell VFX pop with maximum clarity.

signal world_changed(world_index: int, world_name: String)

@export var current_world_index: int = 8 # Default to the dark cosmic purple world matching the user's aesthetic!

# References to arena nodes
@onready var world_env: WorldEnvironment = get_parent().find_child("WorldEnvironment", true, false) as WorldEnvironment
@onready var sun_light: DirectionalLight3D = get_parent().find_child("DirectionalLight3D", true, false) as DirectionalLight3D
@onready var ground_mesh: MeshInstance3D = get_parent().find_child("Ground", true, false).find_child("MeshInstance3D", true, false) as MeshInstance3D
@onready var path_mesh: MeshInstance3D = get_parent().find_child("SandPath", true, false) as MeshInstance3D
@onready var rock_cluster: Node3D = get_parent().find_child("RockCluster", true, false) as Node3D
@onready var trees_group: Node3D = get_parent().find_child("Trees", true, false) as Node3D
@onready var gems_group: Node3D = get_parent().find_child("Gems", true, false) as Node3D

const WORLDS_DATA: Array[Dictionary] = [
	{
		"name": "🌲 Emerald Plains",
		"subtitle": "Deep Forest Meadow",
		"ground_color": Color("#243D1E"),  # Dark rich moss green
		"path_color": Color("#3D301E"),    # Dark earth path
		"path_visible": true,
		"sun_color": Color("#FFF4D6"),
		"sun_energy": 0.95,
		"ambient_color": Color("#1E3218"),
		"ambient_energy": 0.75,
		"sky_color": Color("#1A2B15"),
		"rock_color": Color("#3D453C"),
		"foliage_color": Color("#325C2B"),
		"trunk_color": Color("#382314"),
		"gem_color": Color("#F472B6"),
		"gem_emission": Color("#EC4899"),
		"gem_emission_energy": 1.2,
		"exposure": 0.98
	},
	{
		"name": "🏜️ Desert Mirage",
		"subtitle": "Canyon Dusk Sandstone",
		"ground_color": Color("#5A371E"),  # Deep canyon dusk
		"path_color": Color("#3F2514"),    # Dark sandstone path
		"path_visible": true,
		"sun_color": Color("#FFE0B2"),
		"sun_energy": 0.92,
		"ambient_color": Color("#382213"),
		"ambient_energy": 0.75,
		"sky_color": Color("#3D2514"),
		"rock_color": Color("#543018"),
		"foliage_color": Color("#3E5C32"),
		"trunk_color": Color("#3D2211"),
		"gem_color": Color("#38BDF8"),
		"gem_emission": Color("#0284C7"),
		"gem_emission_energy": 1.3,
		"exposure": 0.98
	},
	{
		"name": "❄️ Frostbite Tundra",
		"subtitle": "Twilight Glacial Abyss",
		"ground_color": Color("#1E2C3D"),  # Deep twilight navy ice
		"path_color": Color("#2D4258"),    # Muted dark glacial slate
		"path_visible": true,
		"sun_color": Color("#D0E5F8"),
		"sun_energy": 0.88,
		"ambient_color": Color("#162332"),
		"ambient_energy": 0.75,
		"sky_color": Color("#182330"),
		"rock_color": Color("#283A4E"),
		"foliage_color": Color("#3E6888"),
		"trunk_color": Color("#1C232D"),
		"gem_color": Color("#60A5FA"),
		"gem_emission": Color("#2563EB"),
		"gem_emission_energy": 1.4,
		"exposure": 0.98
	},
	{
		"name": "🌋 Magma Core",
		"subtitle": "Volcanic Obsidian Caldera",
		"ground_color": Color("#16141A"),  # Deep basalt obsidian
		"path_color": Color("#852500"),    # Molten deep ember river
		"path_visible": true,
		"sun_color": Color("#FF8C42"),
		"sun_energy": 0.85,
		"ambient_color": Color("#381810"),
		"ambient_energy": 0.7,
		"sky_color": Color("#16141A"),
		"rock_color": Color("#262228"),
		"foliage_color": Color("#C23B15"),
		"trunk_color": Color("#141216"),
		"gem_color": Color("#EF4444"),
		"gem_emission": Color("#DC2626"),
		"gem_emission_energy": 1.6,
		"exposure": 0.96
	},
	{
		"name": "🍄 Mystic Grove",
		"subtitle": "Bioluminescent Twilight Marsh",
		"ground_color": Color("#221535"),  # Deep amethyst velvet
		"path_color": Color("#143530"),    # Dark teal enchanted moss
		"path_visible": true,
		"sun_color": Color("#C084FC"),
		"sun_energy": 0.85,
		"ambient_color": Color("#2E1446"),
		"ambient_energy": 0.75,
		"sky_color": Color("#1E122E"),
		"rock_color": Color("#2D1B42"),
		"foliage_color": Color("#0F766E"),
		"trunk_color": Color("#4C1D95"),
		"gem_color": Color("#C084FC"),
		"gem_emission": Color("#9333EA"),
		"gem_emission_energy": 1.4,
		"exposure": 0.98
	},
	{
		"name": "🏰 Castle Ruins",
		"subtitle": "Midnight Stone Courtyard",
		"ground_color": Color("#25282E"),  # Dark granite cobblestone
		"path_color": Color("#383E46"),    # Weathered slate path
		"path_visible": true,
		"sun_color": Color("#FFE8B8"),
		"sun_energy": 0.92,
		"ambient_color": Color("#1E2126"),
		"ambient_energy": 0.75,
		"sky_color": Color("#1C1E23"),
		"rock_color": Color("#2E333B"),
		"foliage_color": Color("#2E4830"),
		"trunk_color": Color("#24211D"),
		"gem_color": Color("#EAB308"),
		"gem_emission": Color("#CA8A04"),
		"gem_emission_energy": 1.3,
		"exposure": 0.98
	},
	{
		"name": "🌊 Pirate Cove",
		"subtitle": "Midnight Coral Lagoon",
		"ground_color": Color("#453828"),  # Dark wet shore sand
		"path_color": Color("#164048"),    # Deep dark ocean tide
		"path_visible": true,
		"sun_color": Color("#FFEED0"),
		"sun_energy": 0.92,
		"ambient_color": Color("#1E2E38"),
		"ambient_energy": 0.75,
		"sky_color": Color("#1A252D"),
		"rock_color": Color("#3B342A"),
		"foliage_color": Color("#156950"),
		"trunk_color": Color("#382012"),
		"gem_color": Color("#10B981"),
		"gem_emission": Color("#059669"),
		"gem_emission_energy": 1.3,
		"exposure": 0.98
	},
	{
		"name": "☠️ Cursed Swamp",
		"subtitle": "Toxic Witch's Mire",
		"ground_color": Color("#1D2318"),  # Dark murky bog
		"path_color": Color("#22461A"),    # Dark algae moss path
		"path_visible": true,
		"sun_color": Color("#B8DBAC"),
		"sun_energy": 0.85,
		"ambient_color": Color("#161C12"),
		"ambient_energy": 0.7,
		"sky_color": Color("#171D13"),
		"rock_color": Color("#20251C"),
		"foliage_color": Color("#4D7C0F"),
		"trunk_color": Color("#1A1612"),
		"gem_color": Color("#84CC16"),
		"gem_emission": Color("#65A30D"),
		"gem_emission_energy": 1.4,
		"exposure": 0.96
	},
	{
		"name": "🌌 Cosmic Void",
		"subtitle": "Astral Deep Space Abyss",
		"ground_color": Color("#141026"),  # The exact deep dark purple from user's image!
		"path_color": Color("#241B44"),    # Dark celestial indigo stone (no blinding neon!)
		"path_visible": true,
		"sun_color": Color("#C8D4F8"),
		"sun_energy": 0.88,
		"ambient_color": Color("#1D1438"),
		"ambient_energy": 0.75,
		"sky_color": Color("#120E22"),
		"rock_color": Color("#201836"),
		"foliage_color": Color("#9D4EDD"),
		"trunk_color": Color("#0F0B1C"),
		"gem_color": Color("#38BDF8"),
		"gem_emission": Color("#0284C7"),
		"gem_emission_energy": 1.5,
		"exposure": 0.98
	},
	{
		"name": "👑 Seraph Sanctuary",
		"subtitle": "Sacred Twilight Citadel",
		"ground_color": Color("#181232"),  # Exact rich dark purple from the reference picture!
		"path_color": Color("#281B4E"),    # Deep dark amethyst sanctuary path
		"path_visible": true,
		"sun_color": Color("#E0D0F8"),
		"sun_energy": 0.85,
		"ambient_color": Color("#22163A"),
		"ambient_energy": 0.75,
		"sky_color": Color("#140E2A"),
		"rock_color": Color("#261B42"),
		"foliage_color": Color("#A855F7"),
		"trunk_color": Color("#160E28"),
		"gem_color": Color("#F59E0B"),
		"gem_emission": Color("#D97706"),
		"gem_emission_energy": 1.5,
		"exposure": 0.98
	}
]

func _ready() -> void:
	call_deferred("apply_world", current_world_index)

func next_world() -> void:
	current_world_index = (current_world_index + 1) % WORLDS_DATA.size()
	apply_world(current_world_index)

func prev_world() -> void:
	current_world_index = (current_world_index - 1 + WORLDS_DATA.size()) % WORLDS_DATA.size()
	apply_world(current_world_index)

func apply_world(index: int) -> void:
	current_world_index = clamp(index, 0, WORLDS_DATA.size() - 1)
	var data: Dictionary = WORLDS_DATA[current_world_index]
	
	# 1. Update Ground
	if ground_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data["ground_color"]
		mat.roughness = 0.92
		ground_mesh.set_surface_override_material(0, mat)
		
	# 2. Update Path / Feature Stream
	if path_mesh:
		path_mesh.visible = data["path_visible"]
		var path_mat := StandardMaterial3D.new()
		path_mat.albedo_color = data["path_color"]
		path_mat.roughness = 0.9
		# Gentle soft glow only on lava; no blinding neon!
		if current_world_index == 3:
			path_mat.emission_enabled = true
			path_mat.emission = data["path_color"]
			path_mat.emission_energy_multiplier = 0.35
		path_mesh.set_surface_override_material(0, path_mat)
		
	# 3. Update Lighting & Tonemapping
	if sun_light:
		sun_light.light_color = data["sun_color"]
		sun_light.light_energy = data["sun_energy"]
		
	if world_env and world_env.environment:
		var env := world_env.environment
		env.background_color = data["sky_color"]
		env.ambient_light_color = data["ambient_color"]
		env.ambient_light_energy = data["ambient_energy"]
		env.tonemap_exposure = data["exposure"]
		
	# 4. Update Rocks
	if rock_cluster:
		var rock_mat := StandardMaterial3D.new()
		rock_mat.albedo_color = data["rock_color"]
		rock_mat.roughness = 0.88
		for child in rock_cluster.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).set_surface_override_material(0, rock_mat)
				
	# 5. Update Trees / Obstacles
	if trees_group:
		var foliage_mat := StandardMaterial3D.new()
		foliage_mat.albedo_color = data["foliage_color"]
		if current_world_index == 4: # Soft glow on mystic mushrooms
			foliage_mat.emission_enabled = true
			foliage_mat.emission = data["foliage_color"]
			foliage_mat.emission_energy_multiplier = 0.3
			
		var trunk_mat := StandardMaterial3D.new()
		trunk_mat.albedo_color = data["trunk_color"]
		
		for tree_node in trees_group.get_children():
			var leaves := tree_node.find_child("Leaves", true, false) as MeshInstance3D
			var trunk := tree_node.find_child("Trunk", true, false) as MeshInstance3D
			if leaves:
				leaves.set_surface_override_material(0, foliage_mat)
			if trunk:
				trunk.set_surface_override_material(0, trunk_mat)

	# 6. Update Floating Gems
	if gems_group:
		var gem_mat := StandardMaterial3D.new()
		gem_mat.albedo_color = data["gem_color"]
		gem_mat.emission_enabled = true
		gem_mat.emission = data["gem_emission"]
		gem_mat.emission_energy_multiplier = data["gem_emission_energy"]
		gem_mat.roughness = 0.25
		
		for gem in gems_group.get_children():
			var gem_mesh := gem.find_child("MeshInstance3D", true, false) as MeshInstance3D
			if gem_mesh:
				gem_mesh.set_surface_override_material(0, gem_mat)

	world_changed.emit(current_world_index, data["name"])
