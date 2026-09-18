# 🤖 Person 4: Bot AI, HUD & Match Manager

## 🎯 Role Overview
You are responsible for populating the arena with intelligent enemy wizard bots, creating the mobile HUD overlay, and managing the match lifecycle (kill feed, alive counter, victory/defeat).

---

## 📁 Files You Own
- `scenes/bots/bot.tscn`
- `scripts/ai/bot_ai.gd`
- `scenes/ui/hud.tscn`
- `scripts/ui/hud.gd`
- `scripts/managers/game_manager.gd`

---

## 📋 Exact Tasks to Implement
1. **Wizard Bot AI (`bot_ai.gd`)**:
   - `CharacterBody3D` with `NavigationAgent3D`.
   - State Machine:
     * **FLEE_STORM**: If outside the shrinking circle, prioritize sprinting to safety.
     * **ATTACK_TARGET**: If an opponent is in range (12m), turn and cast spells with small aim inaccuracy.
     * **CHASE_XP**: Seek out nearby XP crystals.
     * **ROAM**: Wander randomly across the NavMesh.
2. **Mobile HUD (`hud.tscn`)**:
   - Responsive CanvasLayer for mobile phone screens.
   - Top Bar: "Alive: 15", "Kills: 0".
   - Health bar (ProgressBar) & Level/XP progress.
   - Victory Royale #1 and Defeat Game Over popups.
3. **Game Manager (`game_manager.gd`)**:
   - Spawns 12-15 bots on random NavMesh coordinates at start.
   - Tracks living combatants.
   - When player dies → triggers Defeat screen.
   - When only 1 entity remains and it's the player → triggers Victory screen.

---

## 🤖 Copy-Paste AI Prompt

Copy and paste the entire block below into your AI assistant:

```text
You are an expert Godot 4.3 GDScript developer building a 3D mobile battle royale game like Magica.io.
Your responsibility is the NavMesh Bot AI, Match HUD, and the Game Manager loop.

Please generate complete, production-ready Godot 4.3 code and scene structures for the following:

1. scenes/bots/bot.tscn & scripts/ai/bot_ai.gd:
   - Root node: CharacterBody3D (in group "combatants").
   - Attached components: CollisionShape3D, Visual Mesh (voxel wizard with distinct colored robe), NavigationAgent3D, HealthComponent.
   - AI State Machine (Enum: ROAM, CHASE_XP, ATTACK_TARGET, FLEE_STORM):
     * FLEE_STORM: If outside the safe storm circle, prioritize pathfinding toward the safe center.
     * ATTACK_TARGET: If a player or rival bot is within 12.0m line-of-sight, stop, rotate to face them, and fire a spell with a 1.5s cooldown (with small aim inaccuracy).
     * CHASE_XP: If an XP gem is nearby, pathfind to it.
     * ROAM: Pick a random reachable point on the NavMesh and walk toward it at speed 5.5 m/s.

2. scenes/ui/hud.tscn & scripts/ui/hud.gd:
   - CanvasLayer designed for mobile screens (anchors responsive to aspect ratios).
   - Top Bar:
     * "Alive: X" label (updates dynamically as bots die).
     * "Kills: Y" counter.
   - Bottom Left/Center:
     * Player Health Bar (styled green/red ProgressBar).
     * Level & XP Bar ("Lv. 1 [====    ]").
   - Match End Overlays:
     * "VICTORY ROYALE #1" popup banner with Restart button.
     * "DEFEATED - RANK #X" banner with Retry button.

3. scripts/managers/game_manager.gd (Autoload / Match Controller):
   - Initializes the match: Spawns 12-15 bot instances at random positions on the arena NavMesh.
   - Registers all combatants. Listens to `died` signal on every entity.
   - Decrements "Alive" count when an entity dies.
   - If Player dies -> Shows DEFEAT.
   - If Alive == 1 and Player is alive -> Shows VICTORY!
   - Restart button reloads the current scene: `get_tree().reload_current_scene()`.

Provide clean, fully commented Godot 4.3 typed GDScript code and exact node hierarchies.
```
