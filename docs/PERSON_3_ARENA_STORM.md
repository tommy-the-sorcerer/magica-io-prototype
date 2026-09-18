# 🗺️ Person 3: Arena, Shrinking Storm & Voxel Art

## 🎯 Role Overview
You are responsible for the battlefield world, the 3D aesthetic and lighting, the Battle Royale shrinking storm barrier, and the breakable loot that drops XP.

---

## 📁 Files You Own
- `scenes/arena/arena.tscn`
- `scenes/environment/world_env.tres`
- `scenes/environment/storm_zone.tscn`
- `scripts/environment/storm.gd`
- `scenes/environment/loot_crate.tscn`
- `scenes/environment/xp_gem.tscn`

---

## 📋 Exact Tasks to Implement
1. **World Environment & Lighting (`world_env.tres`)**:
   - ACES Tonemapping for vibrant, punchy colors.
   - Glow/Bloom enabled so magic spells radiate light.
   - Warm golden directional sun with soft shadows.
2. **3D Voxel Arena (`arena.tscn`)**:
   - 80x80m grassy ground grid with boundary walls.
   - Wrapped in a `NavigationRegion3D` so bots can navigate.
   - Stone pillars and trees for tactical cover.
3. **Shrinking Storm Circle (`storm.gd`)**:
   - Glowing purple/cyan cylindrical forcefield.
   - Shrinks from radius 45m down to 5m over 180 seconds.
   - Deals 5 tick damage every 0.5s to any player or bot caught outside.
4. **Breakable Crates & XP Crystals**:
   - Wooden voxel crates that break when hit by spells.
   - Dropped gems float, rotate, and magnetize towards nearby players to award XP.

---

## 🤖 Copy-Paste AI Prompt

Copy and paste the entire block below into your AI assistant:

```text
You are an expert Godot 4.3 GDScript developer building a 3D mobile battle royale game like Magica.io.
Your responsibility is the 3D Voxel Arena, the Battle Royale Shrinking Storm Zone, Breakable Crates, and World Environment.

Please generate complete, production-ready Godot 4.3 code and scene structures for the following:

1. scenes/environment/world_env.tres & Arena Lighting:
   - DirectionalLight3D setup: Warm golden sun (Color: #FFF4E0, Energy: 1.2), soft directional shadows enabled, pitched at -50° angle.
   - WorldEnvironment config:
     * Tonemap Mode: ACES (gives rich, vibrant, punchy mobile colors).
     * Glow/Bloom: Enabled, Intensity 1.2, Bloom threshold 0.8 (makes fireballs and magical runes glow).

2. scenes/arena/arena.tscn:
   - Ground plane (e.g. 80x80 meter voxel green grass grid).
   - Perimeter stone block boundary walls.
   - Root wrapped in a `NavigationRegion3D` with baked NavMesh so bots can walk around obstacles.
   - Scattered cover obstacles: Stone pillars, trees, and destructible crates.

3. scenes/environment/storm_zone.tscn & scripts/environment/storm.gd:
   - The shrinking safe zone ring (Battle Royale mechanic).
   - Visual: A large Cylinder Mesh with a translucent glowing purple/neon-cyan material (Alpha 0.35, Emission purple glow).
   - Shrinking Logic: Starts with radius = 45m. Over a match duration of 180 seconds, it periodically shrinks in 3 phases down to radius = 5m.
   - Damage Logic: Every 0.5s, checks all active entities in group "combatants" (Player and Bots). If `entity.global_position.distance_to(storm_center) > current_radius`, deal 5 tick damage via their `HealthComponent`.

4. scenes/environment/loot_crate.tscn & scenes/environment/xp_gem.tscn:
   - `loot_crate.tscn`: StaticBody3D with a wooden voxel mesh + HealthComponent (20 HP). When destroyed, explodes into pieces and spawns 3-5 XP gems.
   - `xp_gem.tscn`: Area3D with a rotating, bobbing green/blue crystal. When a player or bot gets within 4.0m, the gem magnetizes and accelerates toward them. On contact, awards +10 XP and calls `queue_free()`.

Provide clean, fully commented Godot 4.3 typed GDScript code and exact node hierarchies.
```
