# 📋 Master Team Work Division & Architecture

This document establishes the project rules, file boundaries, and integration guidelines for our 4-person development team.

---

## 🛡️ The Zero Merge-Conflict Rule

To ensure all 4 team members can commit and push simultaneously without overwriting each other's work:

1. **Strict File Ownership**: Only edit files inside your assigned directories.
2. **Component & Signal-Based Communication**: Do not hardcode direct references to other teammates' nodes. Use Godot Signals:
   - When Player casts a spell: emit `spell_cast(spell_scene, origin, direction)`
   - When an entity takes damage: call `take_damage(amount, dealer)` on its `HealthComponent`
   - When an entity dies: `HealthComponent` emits `died`
3. **Integration Point**: The only scene that combines all 4 pieces is `scenes/arena/arena.tscn` (coordinated through `GameManager`).

---

## 👥 Responsibility Matrix

| Role | Teammate | Assigned Scenes & Scripts | Key Deliverable |
| :--- | :--- | :--- | :--- |
| **Person 1** | **Player & Mobile Controls** | `scenes/ui/joystick/`, `scenes/player/`, `scripts/player/`, `scripts/camera/` | Dual virtual joysticks + 3D player movement + wobble-walk + 45° follow camera |
| **Person 2** | **Spells, Combat & VFX** | `scenes/spells/`, `scripts/spells/`, `scripts/combat/`, `scenes/vfx/` | Fireball AoE + Ice Lance pierce + HealthComponent + explosion particles |
| **Person 3** | **Arena, Storm & Environment** | `scenes/arena/`, `scenes/environment/`, `scripts/environment/`, `assets/models/` | 3D Voxel arena + shrinking storm barrier + breakable crates + XP gems |
| **Person 4** | **Bot AI, HUD & Match Loop** | `scenes/bots/`, `scripts/ai/`, `scenes/ui/hud/`, `scripts/managers/` | 10-15 NavMesh wizard bots + Mobile HUD + match win/loss manager |

---

## 🔄 Match Flow & System Lifecycle

```
                  [ Game Starts ]
                         │
        ┌────────────────┴────────────────┐
        ▼                                 ▼
[ Player Spawns ]                 [ 12 Bots Spawn ]
(Controlled by P1)                (Controlled by P4)
        │                                 │
        └────────────────┬────────────────┘
                         ▼
             [ Battle in 3D Arena ] (P3)
             - Crates destroyed for XP (P3)
             - Spells fired & colliding (P2)
             - Damage handled by HealthComponent (P2)
                         │
                         ▼
             [ Storm Zone Shrinks ] (P3)
             - Forces players & bots to center
             - Tick damage outside safe radius
                         │
                         ▼
              [ Elimination Check ] (P4)
             - Alive count decreases on HUD
             - If Player dies ──> DEFEATED Screen
             - If 1 left alive ──> VICTORY ROYALE Screen
```

---

## 📖 Individual Task Specs & Prompts

Refer to the individual documents for exact prompt specifications:
- [`PERSON_1_MOBILE_CONTROLS.md`](./PERSON_1_MOBILE_CONTROLS.md)
- [`PERSON_2_COMBAT_VFX.md`](./PERSON_2_COMBAT_VFX.md)
- [`PERSON_3_ARENA_STORM.md`](./PERSON_3_ARENA_STORM.md)
- [`PERSON_4_BOTS_HUD.md`](./PERSON_4_BOTS_HUD.md)
