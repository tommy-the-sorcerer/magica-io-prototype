# 🧙‍♂️ Magica.io Mobile Prototype

A 3D Voxel Battle Royale mobile game built with **Godot 4.3 (GDScript)**, inspired by *Magica.io*.

Features fast-paced spellcasting, a shrinking storm circle, dual-touch mobile joysticks, voxel graphics, and autonomous AI bots in an arena deathmatch.

---

## 🚀 Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Engine** | **Godot 4.3 (Standard 64-bit)** |
| **Language** | **GDScript 2.0** (Typed) |
| **Renderer** | **Mobile (Vulkan / GLES3 fallback)** |
| **3D Art & Voxels** | MagicaVoxel / Kenney / KayKit 3D (.gltf / .glb) |
| **Input** | Dual On-Screen Virtual Joysticks (Touch / Mouse Emulation) |
| **Bot AI** | Godot `NavigationAgent3D` + `NavigationRegion3D` |
| **Target Platforms** | Android (.apk / .aab) & Desktop Playtest |

---

## 👥 4-Person Team Distribution & Architecture

To avoid Git merge conflicts, the codebase is modularized so each person exclusively owns their own scenes and scripts:

```
magica-io-prototype/
├── scenes/
│   ├── player/         <-- 🕹️ Person 1 (Player Character Body)
│   ├── ui/joystick/    <-- 🕹️ Person 1 (Dual Virtual Touch Joysticks)
│   ├── spells/         <-- 🔥 Person 2 (Fireball, Ice Lance, Projectiles)
│   ├── vfx/            <-- 🔥 Person 2 (Explosion, Hit Sparks)
│   ├── arena/          <-- 🗺️ Person 3 (3D Voxel Map & Cover)
│   ├── environment/    <-- 🗺️ Person 3 (Storm Zone, Crates, XP Gems)
│   ├── bots/           <-- 🤖 Person 4 (NavMesh Wizard Bots)
│   └── ui/hud/         <-- 🤖 Person 4 (Mobile HUD, Alive Counter, Game Over)
├── scripts/
│   ├── player/         <-- 🕹️ Person 1
│   ├── camera/         <-- 🕹️ Person 1
│   ├── spells/         <-- 🔥 Person 2
│   ├── combat/         <-- 🔥 Person 2 (HealthComponent)
│   ├── environment/    <-- 🗺️ Person 3
│   ├── ai/             <-- 🤖 Person 4
│   └── managers/       <-- 🤖 Person 4 (GameManager)
└── assets/
    ├── models/
    ├── textures/
    ├── particles/
    └── audio/
```

### Detailed Guides & AI Prompts for Each Role:
- [Person 1: Mobile Controls & Player Movement](docs/PERSON_1_MOBILE_CONTROLS.md)
- [Person 2: Spells, Combat & VFX Particles](docs/PERSON_2_COMBAT_VFX.md)
- [Person 3: Arena, Shrinking Storm & Voxel Art](docs/PERSON_3_ARENA_STORM.md)
- [Person 4: Bot AI, Mobile HUD & Match Loop](docs/PERSON_4_BOTS_HUD.md)
- [Master Team Workflow & Matrix](docs/TEAM_WORK_DIVISION.md)

---

## 🕹️ Controls (Mobile & Desktop)

- **Left Thumb / WASD**: 360° Omnidirectional Movement.
- **Right Thumb / Mouse Drag**: Aim spell trajectory indicator.
- **Release Right Thumb / Click**: Cast spell along aimed trajectory.

---

## 🏁 Quick Start for Developers

1. Download **Godot 4.3 (Standard)** from [godotengine.org/download](https://godotengine.org/download).
2. Open Godot → Click **Import** → Select `project.godot` inside this folder.
3. In VS Code, install the extension **"Godot Tools"** for syntax highlighting and autocomplete.
4. Press `F5` in Godot to run and test!
