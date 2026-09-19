class_name WardrobeManager
extends Node

## Manages Character Cosmetics, Materials, Staff Types, Scarf Colors, and VFX Styles
## Enables swapping wardrobe/skins without rewriting movement or combat logic.

signal skin_changed(skin_name: String)

@export var current_skin_id: String = "arcane_apprentice_default"

# References to character visual slots
var _visuals_root: Node3D = null

## Default Skin Data for Arcane Apprentice
const DEFAULT_SKIN: Dictionary = {
	"id": "arcane_apprentice_default",
	"name": "Arcane Apprentice",
	"robe_primary_color": Color("#1E293B"),      # Dark Navy/Slate Tunic
	"robe_secondary_color": Color("#F8FAFC"),    # Crisp White/Cream Panels
	"trim_color": Color("#F59E0B"),              # Gold Belt & Buckle Trim
	"scarf_color": Color("#DC2626"),             # Flowing Crimson Scarf
	"hair_color": Color("#18181B"),              # Short Dark Messy Hair
	"skin_color": Color("#FCD34D"),              # Stylized Warm Tone
	"boots_gloves_color": Color("#0F172A"),      # Dark Leather Boots & Gloves
	"staff_wood_color": Color("#451A03"),        # Dark Polished Wood
	"crystal_color": Color("#00F0FF"),           # Glowing Blue Magical Core
	"crystal_emission_energy": 3.8,
	"amulet_color": Color("#38BDF8"),            # Chest Amulet
	"amulet_emission_energy": 3.2,
	"projectile_scene": "res://scenes/spells/arcane_bolt.tscn"
}

func _ready() -> void:
	_visuals_root = get_parent().find_child("Visuals", true, false) as Node3D
	call_deferred("apply_skin", DEFAULT_SKIN)

## Applies a skin data dictionary to all character visual sub-components
func apply_skin(skin_data: Dictionary) -> void:
	if not _visuals_root:
		_visuals_root = get_parent().find_child("Visuals", true, false) as Node3D
	if not _visuals_root:
		return

	# Pre-build standard materials from skin data
	var robe_mat := StandardMaterial3D.new()
	robe_mat.albedo_color = skin_data.get("robe_primary_color", DEFAULT_SKIN["robe_primary_color"])
	robe_mat.roughness = 0.7

	var cream_mat := StandardMaterial3D.new()
	cream_mat.albedo_color = skin_data.get("robe_secondary_color", DEFAULT_SKIN["robe_secondary_color"])
	cream_mat.roughness = 0.65

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = skin_data.get("trim_color", DEFAULT_SKIN["trim_color"])
	gold_mat.metallic = 0.75
	gold_mat.roughness = 0.35

	var scarf_mat := StandardMaterial3D.new()
	scarf_mat.albedo_color = skin_data.get("scarf_color", DEFAULT_SKIN["scarf_color"])
	scarf_mat.roughness = 0.6

	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = skin_data.get("hair_color", DEFAULT_SKIN["hair_color"])
	hair_mat.roughness = 0.8

	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = skin_data.get("skin_color", DEFAULT_SKIN["skin_color"])
	skin_mat.roughness = 0.6

	var leather_mat := StandardMaterial3D.new()
	leather_mat.albedo_color = skin_data.get("boots_gloves_color", DEFAULT_SKIN["boots_gloves_color"])
	leather_mat.roughness = 0.75

	var staff_mat := StandardMaterial3D.new()
	staff_mat.albedo_color = skin_data.get("staff_wood_color", DEFAULT_SKIN["staff_wood_color"])
	staff_mat.roughness = 0.8

	var crystal_color: Color = skin_data.get("crystal_color", DEFAULT_SKIN["crystal_color"])
	var crystal_energy: float = skin_data.get("crystal_emission_energy", DEFAULT_SKIN["crystal_emission_energy"])
	var crystal_mat := StandardMaterial3D.new()
	crystal_mat.albedo_color = crystal_color
	crystal_mat.emission_enabled = true
	crystal_mat.emission = crystal_color
	crystal_mat.emission_energy_multiplier = crystal_energy
	crystal_mat.roughness = 0.15

	var amulet_color: Color = skin_data.get("amulet_color", DEFAULT_SKIN["amulet_color"])
	var amulet_energy: float = skin_data.get("amulet_emission_energy", DEFAULT_SKIN["amulet_emission_energy"])
	var amulet_mat := StandardMaterial3D.new()
	amulet_mat.albedo_color = amulet_color
	amulet_mat.emission_enabled = true
	amulet_mat.emission = amulet_color
	amulet_mat.emission_energy_multiplier = amulet_energy
	amulet_mat.roughness = 0.15

	# 1. Apply by Node Names (Multi-mesh rigs)
	var all_meshes := _visuals_root.find_children("*", "MeshInstance3D", true, false)
	for m in all_meshes:
		if not (m is MeshInstance3D):
			continue
		var mesh_inst := m as MeshInstance3D
		var node_name: String = mesh_inst.name.to_lower()

		if node_name.contains("tunic") or node_name.contains("robe") or node_name.contains("skirt"):
			if node_name.contains("panel") or node_name.contains("cream") or node_name.contains("white"):
				mesh_inst.material_override = cream_mat
			else:
				mesh_inst.material_override = robe_mat
		elif node_name.contains("belt") or node_name.contains("gold") or node_name.contains("trim"):
			mesh_inst.material_override = gold_mat
		elif node_name.contains("scarf") or node_name.contains("cape"):
			mesh_inst.material_override = scarf_mat
		elif node_name.contains("hair"):
			mesh_inst.material_override = hair_mat
		elif node_name.contains("head") or node_name.contains("face") or node_name.contains("skin") or node_name.contains("body"):
			mesh_inst.material_override = skin_mat
		elif node_name.contains("boot") or node_name.contains("glove") or node_name.contains("leather") or node_name.contains("pouch"):
			mesh_inst.material_override = leather_mat
		elif node_name.contains("staff") or node_name.contains("wood"):
			if node_name.contains("crystal"):
				mesh_inst.material_override = crystal_mat
			else:
				mesh_inst.material_override = staff_mat
		elif node_name.contains("crystal") or node_name.contains("rune"):
			mesh_inst.material_override = crystal_mat
		elif node_name.contains("amulet"):
			mesh_inst.material_override = amulet_mat

		# 2. Also check surface material names inside mesh (Single-mesh skinned character)
		if mesh_inst.mesh:
			for s in range(mesh_inst.mesh.get_surface_count()):
				var surf_mat = mesh_inst.get_surface_override_material(s)
				if not surf_mat and mesh_inst.mesh:
					surf_mat = mesh_inst.mesh.surface_get_material(s)
				if surf_mat:
					var mat_name: String = surf_mat.resource_name.to_lower()
					if mat_name.contains("navy") or mat_name.contains("tunic"):
						mesh_inst.set_surface_override_material(s, robe_mat)
					elif mat_name.contains("cream") or mat_name.contains("robe"):
						mesh_inst.set_surface_override_material(s, cream_mat)
					elif mat_name.contains("gold") or mat_name.contains("trim"):
						mesh_inst.set_surface_override_material(s, gold_mat)
					elif mat_name.contains("crimson") or mat_name.contains("scarf") or mat_name.contains("cape"):
						mesh_inst.set_surface_override_material(s, scarf_mat)
					elif mat_name.contains("hair"):
						mesh_inst.set_surface_override_material(s, hair_mat)
					elif mat_name.contains("skin") or mat_name.contains("head") or mat_name.contains("face"):
						mesh_inst.set_surface_override_material(s, skin_mat)
					elif mat_name.contains("leather") or mat_name.contains("boot") or mat_name.contains("glove"):
						mesh_inst.set_surface_override_material(s, leather_mat)
					elif mat_name.contains("wood") or mat_name.contains("staff"):
						mesh_inst.set_surface_override_material(s, staff_mat)
					elif mat_name.contains("crystal") or mat_name.contains("rune"):
						mesh_inst.set_surface_override_material(s, crystal_mat)

	skin_changed.emit(skin_data.get("name", "Arcane Apprentice"))
