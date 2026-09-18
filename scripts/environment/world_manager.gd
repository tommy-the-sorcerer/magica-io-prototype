class_name WorldManager
extends Node

## Manages 9 Distinct Themed Battle Worlds with tuned lighting, contrast, props, and gems

signal world_changed(world_index: int, world_name: String)

@export var current_world_index: int = 0

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
		"subtitle": "Classic Voxel Meadow",
		"ground_color": Color("#8CC456"),
		"path_color": Color("#F5EA9E"),
		"path_visible": true,
		"sun_color": Color("#FFFBF0"),
		"sun_energy": 1.25,
		"ambient_color": Color("#C2D9B7"),
		"ambient_energy": 0.85,
		"sky_color": Color("#8CC456"),
		"rock_color": Color("#7A8679"),
		"foliage_color": Color("#3B8C54"),
		"trunk_color": Color("#5A3A22"),
		"gem_color": Color("#FF60C8"),
		"gem_emission": Color("#FF38B0"),
		"gem_emission_energy": 1.0,
		"exposure": 1.0
	},
	{
		"name": "🏜️ Desert Mirage",
		"subtitle": "Sun-Drenched Sand Dunes",
		"ground_color": Color("#E8B966"),
		"path_color": Color("#D49646"),
		"path_visible": true,
		"sun_color": Color("#FFF2D4"),
		"sun_energy": 1.45,
		"ambient_color": Color("#EBD1A7"),
		"ambient_energy": 0.9,
		"sky_color": Color("#E8B966"),
		"rock_color": Color("#B86D3B"),
		"foliage_color": Color("#568A48"), # Cacti green
		"trunk_color": Color("#8A552C"),
		"gem_color": Color("#28E0D0"),     # Turquoise
		"gem_emission": Color("#00C8C8"),
		"gem_emission_energy": 1.2,
		"exposure": 1.08
	},
	{
		"name": "❄️ Frostbite Tundra",
		"subtitle": "Glacial Frozen Expanse",
		"ground_color": Color("#D8EAF5"),
		"path_color": Color("#88C2E8"),     # Glacial ice path
		"path_visible": true,
		"sun_color": Color("#E0F2FE"),
		"sun_energy": 1.15,
		"ambient_color": Color("#B0D4EE"),
		"ambient_energy": 0.95,
		"sky_color": Color("#D8EAF5"),
		"rock_color": Color("#5B7288"),     # Blue-gray rock
		"foliage_color": Color("#62A8D4"), # Frosted needles
		"trunk_color": Color("#3B4554"),
		"gem_color": Color("#3B82F6"),     # Deep Sapphire
		"gem_emission": Color("#2563EB"),
		"gem_emission_energy": 1.3,
		"exposure": 1.02
	},
	{
		"name": "🌋 Magma Core",
		"subtitle": "Volcanic Obsidian Caldera",
		"ground_color": Color("#232128"),  # Dark charcoal
		"path_color": Color("#FF4D00"),     # Glowing lava river
		"path_visible": true,
		"sun_color": Color("#FFAA66"),
		"sun_energy": 1.0,
		"ambient_color": Color("#54241B"),
		"ambient_energy": 0.8,
		"sky_color": Color("#232128"),
		"rock_color": Color("#383238"),     # Basalt pillars
		"foliage_color": Color("#FF3300"), # Fire spires
		"trunk_color": Color("#1A181C"),
		"gem_color": Color("#FF2222"),     # Fire Ruby
		"gem_emission": Color("#FF0000"),
		"gem_emission_energy": 2.0,
		"exposure": 0.96
	},
	{
		"name": "🍄 Mystic Grove",
		"subtitle": "Bioluminescent Twilight Marsh",
		"ground_color": Color("#32254A"),  # Twilight purple moss
		"path_color": Color("#24B5A5"),     # Glowing teal spores
		"path_visible": true,
		"sun_color": Color("#D8B4FE"),     # Soft moonlight
		"sun_energy": 0.95,
		"ambient_color": Color("#4A286E"),
		"ambient_energy": 1.0,
		"sky_color": Color("#32254A"),
		"rock_color": Color("#42325A"),
		"foliage_color": Color("#06D6A0"), # Neon cyan mushroom cap
		"trunk_color": Color("#A855F7"),   # Purple stem
		"gem_color": Color("#C084FC"),     # Amethyst
		"gem_emission": Color("#A855F7"),
		"gem_emission_energy": 1.5,
		"exposure": 1.0
	},
	{
		"name": "🏰 Castle Ruins",
		"subtitle": "Ancient Stone Courtyard",
		"ground_color": Color("#5A626A"),  # Cobblestone gray
		"path_color": Color("#9AA4AF"),     # Polished stone
		"path_visible": true,
		"sun_color": Color("#FFF4D6"),
		"sun_energy": 1.25,
		"ambient_color": Color("#8B95A2"),
		"ambient_energy": 0.8,
		"sky_color": Color("#5A626A"),
		"rock_color": Color("#41474E"),     # Dark granite
		"foliage_color": Color("#4B6B4D"), # Mossy vines
		"trunk_color": Color("#423832"),
		"gem_color": Color("#FACC15"),     # Gold Topaz
		"gem_emission": Color("#EAB308"),
		"gem_emission_energy": 1.2,
		"exposure": 1.0
	},
	{
		"name": "🌊 Pirate Cove",
		"subtitle": "Tropical Coral Beach",
		"ground_color": Color("#F6EAC2"),  # Coral white sand
		"path_color": Color("#2DD4BF"),     # Turquoise ocean water
		"path_visible": true,
		"sun_color": Color("#FFFDF5"),
		"sun_energy": 1.35,
		"ambient_color": Color("#BAE6FD"),
		"ambient_energy": 0.9,
		"sky_color": Color("#F6EAC2"),
		"rock_color": Color("#85796A"),
		"foliage_color": Color("#10B981"), # Tropical palm green
		"trunk_color": Color("#78350F"),
		"gem_color": Color("#10B981"),     # Sea Emerald
		"gem_emission": Color("#059669"),
		"gem_emission_energy": 1.2,
		"exposure": 1.05
	},
	{
		"name": "☠️ Cursed Swamp",
		"subtitle": "Toxic Witch's Mire",
		"ground_color": Color("#3B4434"),  # Murky olive mud
		"path_color": Color("#4ADE80"),     # Glowing toxic ooze
		"path_visible": true,
		"sun_color": Color("#CFE7C8"),
		"sun_energy": 0.9,
		"ambient_color": Color("#2E382A"),
		"ambient_energy": 0.85,
		"sky_color": Color("#3B4434"),
		"rock_color": Color("#2D332A"),     # Tombstone slate
		"foliage_color": Color("#84CC16"), # Toxic lime leaves
		"trunk_color": Color("#26221D"),
		"gem_color": Color("#A3E635"),     # Cursed Jade
		"gem_emission": Color("#65A30D"),
		"gem_emission_energy": 1.4,
		"exposure": 0.98
	},
	{
		"name": "🌌 Cosmic Void",
		"subtitle": "Astral Floating Dimension",
		"ground_color": Color("#141324"),  # Deep space navy
		"path_color": Color("#00F0FF"),     # Neon grid line
		"path_visible": true,
		"sun_color": Color("#E0E7FF"),
		"sun_energy": 1.1,
		"ambient_color": Color("#2E2856"),
		"ambient_energy": 1.1,
		"sky_color": Color("#141324"),
		"rock_color": Color("#1F1C38"),     # Obsidian Monolith
		"foliage_color": Color("#F43F5E"), # Neon pink energy spires
		"trunk_color": Color("#0F0E1C"),
		"gem_color": Color("#38BDF8"),     # Cosmic Stardust
		"gem_emission": Color("#0EA5E9"),
		"gem_emission_energy": 2.2,
		"exposure": 1.0
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
		mat.roughness = 0.9
		ground_mesh.set_surface_override_material(0, mat)
		
	# 2. Update Path / Feature Stream
	if path_mesh:
		path_mesh.visible = data["path_visible"]
		var path_mat := StandardMaterial3D.new()
		path_mat.albedo_color = data["path_color"]
		# If volcanic lava or cosmic neon, enable emission!
		if current_world_index == 3 or current_world_index == 8:
			path_mat.emission_enabled = true
			path_mat.emission = data["path_color"]
			path_mat.emission_energy_multiplier = 1.2
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
		rock_mat.roughness = 0.85
		for child in rock_cluster.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).set_surface_override_material(0, rock_mat)
				
	# 5. Update Trees / Obstacles
	if trees_group:
		var foliage_mat := StandardMaterial3D.new()
		foliage_mat.albedo_color = data["foliage_color"]
		if current_world_index == 4 or current_world_index == 8: # Glowing mushrooms / void spires
			foliage_mat.emission_enabled = true
			foliage_mat.emission = data["foliage_color"]
			foliage_mat.emission_energy_multiplier = 0.8
			
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
		gem_mat.roughness = 0.2
		
		for gem in gems_group.get_children():
			var gem_mesh := gem.find_child("MeshInstance3D", true, false) as MeshInstance3D
			if gem_mesh:
				gem_mesh.set_surface_override_material(0, gem_mat)

	world_changed.emit(current_world_index, data["name"])
