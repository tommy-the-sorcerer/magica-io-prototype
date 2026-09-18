# 🕹️ Person 1: Player & Mobile Controls

## 🎯 Role Overview
You are responsible for making the game feel responsive, fluid, and intuitive on mobile touch screens, as well as handling player movement and the signature isometric follow camera.

---

## 📁 Files You Own
- `scenes/ui/joystick.tscn`
- `scripts/ui/joystick.gd`
- `scenes/player/player.tscn`
- `scripts/player/player_controller.gd`
- `scripts/camera/camera_follow.gd`

---

## 📋 Exact Tasks to Implement
1. **Dual Virtual Touch Joystick (`joystick.gd`)**:
   - Create a multi-touch compatible joystick.
   - Left half of screen = Movement Joystick.
   - Right half of screen = Aiming Joystick.
   - Returns a normalized `Vector2` output (-1 to 1).
   - Supports mouse clicks for desktop playtesting.
2. **Player Movement & Voxel Wobble (`player_controller.gd`)**:
   - `CharacterBody3D` that moves based on left joystick vector.
   - Smooth acceleration and deceleration.
   - While moving, programmatically tilt the visual mesh left/right (±5° roll) to create Magica.io's signature wobble walk animation.
3. **Aiming & Spell Triggering**:
   - When right joystick is held, the player rotates toward the aim angle.
   - When right joystick is released (or tapped), if aim magnitude > 0.3, emit `spell_cast(spell_scene, origin, direction)`.
4. **Isometric Follow Camera (`camera_follow.gd`)**:
   - Positioned at a 45° angle above the player with smooth `lerp` tracking.

---

## 🤖 Copy-Paste AI Prompt

Copy and paste the entire block below into your AI assistant:

```text
You are an expert Godot 4.3 GDScript developer building a 3D mobile battle royale game like Magica.io.
Your responsibility is the Player Character Controller, Dual Mobile Virtual Joysticks, and the Isometric Follow Camera.

Please generate complete, production-ready Godot 4.3 code and scene structures for the following:

1. scenes/ui/joystick.tscn & scripts/ui/joystick.gd:
   - A virtual on-screen analog touch joystick for mobile screens.
   - It should support multi-touch (tracking touch index so left and right thumbs don't conflict).
   - Base circle (background) and handle knob (stick).
   - Clamps handle within a max radius (e.g., 80px).
   - Public function `get_output() -> Vector2` returning normalized direction (-1 to 1).
   - When released, smoothly recenters handle and returns Vector2.ZERO.
   - Must work with both mobile touch events and mouse click-and-drag (for PC testing).

2. scenes/player/player.tscn & scripts/player/player_controller.gd:
   - Root node: CharacterBody3D.
   - Children: CollisionShape3D (Capsule), Visuals (Node3D with a voxel block character mesh, wizard hat, and a wand/staff), Marker3D ("CastPoint" in front of the wand).
   - Movement: Reads Left Joystick output (or WASD for fallback). Moves smoothly at speed 7.0 m/s with acceleration.
   - Rotation / Aiming: Reads Right Joystick output. If right stick is dragged, the player rotates smoothly toward the aim direction. If no right stick input, player faces the movement direction.
   - Magica.io "Wobble Walk": Programmatically tilt the visual mesh slightly left/right (Roll: ±5°) in rhythm with movement speed to simulate the signature cute voxel waddling animation.
   - Spell Casting: When the right joystick is released (or on tap), if aim vector magnitude > 0.3, emit a signal `spell_cast(spell_scene, origin_position, forward_direction)`.

3. scripts/camera/camera_follow.gd:
   - Attached to a Camera3D node in the main scene.
   - Placed at an isometric 45° angle (e.g. position offset: Vector3(0, 14, 10), rotation: Vector3(-50, 0, 0)).
   - Uses `transform.origin = transform.origin.lerp(target.global_position + offset, delta * 6.0)` for smooth follow without jitter.

Provide clean, fully commented Godot 4.3 typed GDScript code and exact node instructions.
```
