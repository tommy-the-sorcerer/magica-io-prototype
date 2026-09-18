# 🤖 Person 4: Bot AI, Simulated "Multiplayer" & Match Manager

## 🎯 Role Overview
You are responsible for the core **"Simulated Multiplayer" illusion** of *Magica.io*:
1. Populating the arena with 12-15 wizard bots that look and act like real online players.
2. A fake 3-second **"Matchmaking & Player Search"** loading screen.
3. Realistic gamer tags, country flags, and floating 3D overhead nameplates.
4. An active **Live Kill Feed** in the HUD (e.g. *"🇺🇸 ShadowNinja_99 eliminated 🇩🇪 Blitz"*).
5. Match rules (Alive counter, Victory Royale #1, Defeat screen).

---

## 📁 Files You Own
- `scenes/bots/bot.tscn`
- `scripts/ai/bot_ai.gd`
- `scenes/ui/matchmaking_screen.tscn`
- `scripts/ui/matchmaking.gd`
- `scenes/ui/hud.tscn`
- `scripts/ui/hud.gd`
- `scripts/managers/game_manager.gd`

---

## 📋 Exact Tasks to Implement

### 1. Fake 3-Second Matchmaking Screen (`matchmaking.gd`)
- Display before the match loads:
  - *"Connecting to Region: Best Ping (24ms)..."*
  - Animated player counter: *"Searching for players: 1/15... 6/15... 12/15... 15/15 FOUND!"*
  - Countdown: *"Battle starts in 3... 2... 1!"* then transitions straight into gameplay.

### 2. Realistic Bot Profiles & 3D Nameplates
- Store a list of 50+ realistic gamer tags (e.g., `ShadowNinja_99`, `DragonSlayer_01`, `Alex_FR`, `ProGamer_BR`, `SakuraMage`, `FrostBite`, `CyberWizard`, `Viper_X`, `AlphaWolf`).
- Attach a random country flag emoji (🇺🇸, 🇮🇳, 🇧🇷, 🇩🇪, 🇯🇵, 🇬🇧, 🇫🇷, 🇰🇷, 🇨🇦).
- Give each bot a randomized wizard robe color (blue, red, green, purple, yellow).
- **3D Overhead Nameplate**: Use a `Label3D` (Billboard enabled so it always faces the camera) displaying:
  `[ 🇺🇸 ShadowNinja_99 ]` + a mini overhead HP bar.

### 3. Human-like Bot AI (`bot_ai.gd`)
- State Machine with human quirks:
  * **MATCH_START**: First 2 seconds, bots do small random jitter rotations (like mobile players fidgeting with their thumbs).
  * **FLEE_STORM**: If outside the safe ring, immediately sprint toward the safe center.
  * **PANIC_RETREAT**: When HP < 25%, turn and sprint away from the attacker to stay alive.
  * **ATTACK_TARGET**: If an enemy is within 12m, rotate and shoot fireballs with slight human inaccuracy (±10° variance so they aren't robotic aimbots).
  * **CHASE_XP**: Navigate toward nearby floating gems.
  * **ROAM**: Wander the NavMesh.

### 4. Mobile HUD & Dynamic Kill Feed (`hud.gd`)
- Top Bar:
  * `"Alive: 15 / 15"` (decrements live).
  * `"Kills: 0"`.
  * **Kill Feed** in top-right: Shows recent eliminations fading away after 3s:
    - `🇺🇸 ShadowNinja_99 💥 🇩🇪 Blitz`
    - `👑 YOU 💥 🇧🇷 ProGamer_BR` *(highlighted in gold)*.
- Bottom: Player Health Bar + Level Bar.
- End Screens:
  * **"VICTORY ROYALE #1"** banner with coin reward & Play Again button.
  * **"DEFEATED - RANK #X"** with Spectate / Retry button.

### 5. Game Manager (`game_manager.gd`)
- Spawns the player and 14 bots with randomized names/flags.
- Tracks match eliminations and triggers victory when the player is the last one standing.

---

## 🤖 Copy-Paste AI Prompt

Copy and paste the entire block below into your AI assistant:

```text
You are an expert Godot 4.3 GDScript developer building the simulated online multiplayer system for a 3D mobile battle royale game like Magica.io.
The game runs offline, but simulates a real online battle royale against 14 other players.

Please generate complete, production-ready Godot 4.3 code and scene structures for the following:

1. scenes/ui/matchmaking_screen.tscn & scripts/ui/matchmaking.gd:
   - A fake mobile matchmaking screen.
   - Shows: "Finding Match... Region: Global (28ms)".
   - Uses a Tween / Timer to rapidly count players up: "1/15" -> "7/15" -> "13/15" -> "15/15 Match Found!".
   - Shows a quick 3-second countdown ("Battle in 3... 2... 1!") and transitions to the main arena scene.

2. scenes/bots/bot.tscn & scripts/ai/bot_ai.gd:
   - Root node: CharacterBody3D (group: "combatants").
   - Components: CollisionShape3D, Visual Mesh (voxel wizard), NavigationAgent3D, HealthComponent.
   - Overhead Nameplate: A Label3D with billboard_mode = BILLBOARD_ENABLED.
   - Bot Identity Generator:
     * Picks a random name from an array of 40 gamer tags (e.g. "ShadowNinja_99", "DragonSlayer", "ProGamer_BR", "SakuraMage", "CyberWizard", "Viper_007", "Alex_FR", "FrostByte").
     * Picks a random flag emoji (🇺🇸, 🇮🇳, 🇧🇷, 🇩🇪, 🇯🇵, 🇬🇧, 🇫🇷, 🇰🇷, 🇨🇦).
     * Randomizes robe color via material albedo.
   - Human-Like AI State Machine:
     * MATCH_START: For 1.5 seconds, jitter/rotate randomly like a real player.
     * FLEE_STORM: If outside the safe storm radius, navigate toward the safe center.
     * PANIC_FLEE: If current_health < 30% and under attack, flee in opposite direction of attacker.
     * ATTACK_TARGET: If enemy within 12m line of sight, rotate to face them with slight human inaccuracy (±8° offset) and fire a fireball every 1.6s.
     * CHASE_XP: Move toward nearest XP gem.
     * ROAM: Pick a random point on NavigationRegion3D.

3. scenes/ui/hud.tscn & scripts/ui/hud.gd:
   - CanvasLayer for mobile screens.
   - Top-Left: "Alive: 15", "Kills: 0".
   - Top-Right: Dynamic Kill Feed container (VBoxContainer).
     * Function: `add_kill_feed(killer_name: String, victim_name: String, is_player: bool)`.
     * Spawns a Label that automatically fades out and frees itself after 3.5 seconds.
   - Bottom: Player Health bar + Level Progress bar.
   - Game Over popups: "VICTORY ROYALE #1" and "DEFEATED - RANK #X" with Restart button.

4. scripts/managers/game_manager.gd (Autoload):
   - Spawns 14 bots on the arena NavMesh.
   - Listens to `died` signal from HealthComponents.
   - When an entity dies:
     * Decrements Alive count and updates HUD.
     * Posts message to Kill Feed.
     * If player dies -> Triggers DEFEATED screen showing final rank.
     * If 1 alive and player is alive -> Triggers VICTORY ROYALE screen!
   - Restart button reloads match cleanly.

Provide clean, fully commented Godot 4.3 typed GDScript code and exact node hierarchies.
```
