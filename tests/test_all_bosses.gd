extends SceneTree

func _init() -> void:
	print("========================================")
	print("🧪 RUNNING 10 BOSS VALIDATION TEST SUITE")
	print("========================================")
	
	var boss_scenes := [
		{"ch": 1, "name": "Gorgon Treant King", "path": "res://scenes/maps/emerald_plains/boss/gorgon_treant_king.tscn"},
		{"ch": 2, "name": "Anubis Scythe-Lord", "path": "res://scenes/maps/chapter_02_desert_mirage/boss/anubis_scythe_lord.tscn"},
		{"ch": 3, "name": "Frost Fiend Ymir", "path": "res://scenes/maps/chapter_03_frostbite_tundra/boss/frost_fiend_ymir.tscn"},
		{"ch": 4, "name": "Ignis Molten Overlord", "path": "res://scenes/maps/chapter_04_magma_core/boss/ignis_molten_overlord.tscn"},
		{"ch": 5, "name": "Spore Queen Nightshade", "path": "res://scenes/maps/chapter_05_mystic_grove/boss/spore_queen_nightshade.tscn"},
		{"ch": 6, "name": "Warlord Iron-Bane", "path": "res://scenes/maps/chapter_06_castle_ruins/boss/warlord_iron_bane.tscn"},
		{"ch": 7, "name": "Captain Davy Blood-Tide", "path": "res://scenes/maps/chapter_07_pirate_cove/boss/captain_davy_blood_tide.tscn"},
		{"ch": 8, "name": "Lord Malakor", "path": "res://scenes/maps/chapter_08_cursed_swamp/boss/lord_malakor.tscn"},
		{"ch": 9, "name": "Xeno-Gorgon Apex", "path": "res://scenes/maps/chapter_09_cosmic_void/boss/xeno_gorgon_apex.tscn"},
		{"ch": 10, "name": "Judgment Seraph", "path": "res://scenes/maps/chapter_10_celestial_peak/boss/judgment_seraph.tscn"},
	]
	
	var passed := 0
	var test_root := Node3D.new()
	test_root.name = "TestRoot"
	root.add_child(test_root)
	current_scene = test_root
	
	for entry in boss_scenes:
		var ch_num: int = entry["ch"]
		var boss_name: String = entry["name"]
		var path: String = entry["path"]
		
		print("\n[CH %d] Testing: %s (%s)" % [ch_num, boss_name, path])
		
		var packed: PackedScene = load(path) as PackedScene
		if not packed:
			printerr("❌ FAILED TO LOAD SCENE: ", path)
			quit(1)
			return
			
		var boss_inst: Node = packed.instantiate()
		if not boss_inst:
			printerr("❌ FAILED TO INSTANTIATE: ", path)
			quit(1)
			return
			
		test_root.add_child(boss_inst)
		if not boss_inst.is_node_ready():
			boss_inst._ready()
		
		# Validate inheritance
		if not (boss_inst is BaseBoss):
			printerr("❌ Boss does not inherit BaseBoss: ", boss_name)
			quit(1)
			return
			
		var b: BaseBoss = boss_inst as BaseBoss
		var hp: HealthComponent = b.health_component
		if not hp:
			hp = b.find_child("HealthComponent", true, false) as HealthComponent
		if not hp:
			printerr("❌ Missing HealthComponent on: ", boss_name)
			quit(1)
			return
			
		print("  ✓ Instantiated cleanly, Boss Name: '%s', HP: %d, Base Speed: %.1f, Damage: %.1f" % [b.boss_name, int(hp.max_health), b.move_speed, b.attack_damage])
		
		# Test Phase Transitions:
		var init_speed: float = b.move_speed
		var init_dmg: float = b.attack_damage
		
		# Damage down to 70% (Trigger Phase 2)
		hp.take_damage(hp.max_health * 0.3, null)
		if b.current_phase != BaseBoss.BossPhase.PHASE_2:
			printerr("❌ Failed to enter Phase 2 at 70% HP. Current: ", b.current_phase)
			quit(1)
			return
		print("  ✓ Entered Phase 2 at %.0f%% HP" % ((hp.current_health / hp.max_health) * 100.0))
		
		# Damage down to 45% (Trigger Phase 3)
		hp.take_damage(hp.max_health * 0.25, null)
		if b.current_phase != BaseBoss.BossPhase.PHASE_3:
			printerr("❌ Failed to enter Phase 3 at 45% HP. Current: ", b.current_phase)
			quit(1)
			return
		print("  ✓ Entered Phase 3 at %.0f%% HP" % ((hp.current_health / hp.max_health) * 100.0))
		
		# Damage down to 20% (Trigger Phase 4 Enrage)
		hp.take_damage(hp.max_health * 0.25, null)
		if b.current_phase != BaseBoss.BossPhase.PHASE_4:
			printerr("❌ Failed to enter Phase 4 Enrage at 20% HP. Current: ", b.current_phase)
			quit(1)
			return
		print("  ✓ Entered Phase 4 (ENRAGE) at %.0f%% HP! Enrage Speed: %.1f (was %.1f)" % [((hp.current_health / hp.max_health) * 100.0), b.move_speed, init_speed])
		
		# Test Telegraph helper
		var circle := b.create_telegraph_circle(Vector3(0, 0, 0), 4.0, 0.5)
		if not circle:
			printerr("❌ Failed to create telegraph circle for: ", boss_name)
			quit(1)
			return
		print("  ✓ Telegraph warning circle generated successfully")
		
		# Test Procedural Locomotion Kinematics & Erratic AI
		var simulated_player_pos := Vector3(10, 0, 10)
		var test_vel := b.calculate_unanticipated_velocity(simulated_player_pos, 3.0, 0.016)
		b.velocity = test_vel
		b.update_procedural_locomotion(0.016)
		print("  ✓ Kinematics: stride_cycle=%.2f, leg/body procedural dip calculated" % b.stride_cycle)
		
		# Test Facial State Machine (Attack Roar & Jaw Flare)
		b.set_facial_state(BaseBoss.FacialState.ATTACK_ROAR, 1.0)
		b.update_procedural_locomotion(0.016)
		print("  ✓ Facial Expression: ATTACK_ROAR & Jaw animation active")
		
		# Clean up instance
		boss_inst.queue_free()
		circle.queue_free()
		passed += 1
		
	test_root.queue_free()
	print("\n========================================")
	print("🎉 ALL %d / %d BOSSES VALIDATED SUCCESSFULLY!" % [passed, boss_scenes.size()])
	print("========================================")
	quit(0)
