# 🔥 Person 2: Spells, Combat & VFX

## 🎯 Role Overview
You are responsible for the offensive magic attacks, damage detection, health tracking, and the visual particle explosions that make hits feel impactful.

---

## 📁 Files You Own
- `scripts/combat/health_component.gd`
- `scripts/spells/projectile.gd`
- `scenes/spells/fireball.tscn`
- `scenes/spells/ice_lance.tscn`
- `scenes/vfx/explosion_particles.tscn`

---

## 📋 Exact Tasks to Implement
1. **Health Component (`health_component.gd`)**:
   - Reusable node attached to Player, Bots, and Crates.
   - Manages `current_health`, `take_damage()`, `heal()`, and emits `died`.
   - Flashes parent mesh briefly upon damage.
2. **Base Projectile (`projectile.gd`)**:
   - Moves forward in 3D space (`Area3D`).
   - Ignores the caster who launched it.
   - Explodes on contact with walls or damageable entities.
3. **Spells**:
   - **Fireball**: Deals 25 AoE damage in a 3.0m radius with knockback and fiery particle explosion.
   - **Ice Lance**: High velocity piercing spike dealing 35 single-target damage with a 40% slow debuff.
4. **VFX Particles (`explosion_particles.tscn`)**:
   - `GPUParticles3D` shockwave ring and flying glowing embers.
   - Auto-deletes itself (`queue_free()`) upon completion.

---

## 🤖 Copy-Paste AI Prompt

Copy and paste the entire block below into your AI assistant:

```text
You are an expert Godot 4.3 GDScript developer building a 3D mobile battle royale game like Magica.io.
Your responsibility is the Magic Spells, Projectile Physics, Damage/Health System, and Particle Effects.

Please generate complete, production-ready Godot 4.3 code and scene structures for the following:

1. scripts/combat/health_component.gd:
   - Node to attach to any damageable entity (Player, Bots, Crates).
   - Variables: `max_health: float = 100.0`, `current_health: float`.
   - Signals: `health_changed(current: float, max_health: float)`, `damaged(amount: float, source: Node)`, `died()`.
   - Functions: `take_damage(amount: float, source: Node = null)`, `heal(amount: float)`.
   - Floating combat flash: Briefly flash the parent mesh white/red upon taking damage.

2. scenes/spells/projectile.gd & scenes/spells/fireball.tscn:
   - Root node: Area3D.
   - Children: CollisionShape3D (Sphere), MeshInstance3D (Voxel/Sphere with glowing orange/yellow unshaded emission material), OmniLight3D (subtle orange point light), GPUParticles3D (trailing smoke and spark embers).
   - Behavior: Moves forward along its `-transform.basis.z` vector at speed 18.0 m/s.
   - Lifetime timer: Automatically explodes after 2.5 seconds or on collision.
   - Collision detection: `body_entered` and `area_entered`. Ignores the caster who shot it.
   - On impact: Spawns the explosion VFX, deals 25 AoE damage to all entities with a `HealthComponent` within a 3.0m blast radius, and applies knockback velocity. `queue_free()` afterwards.

3. scenes/spells/ice_lance.tscn:
   - A high-speed (28.0 m/s) piercing crystalline spike projectile.
   - Deals 35 direct single-target damage and applies a 40% slow movement speed debuff for 2.0 seconds.

4. scenes/vfx/explosion_particles.tscn:
   - A self-destroying scene with GPUParticles3D (bursting fire embers, shockwave ring mesh).
   - One-shot mode enabled. Connects `finished` signal to `queue_free()`.

Provide clean, fully commented Godot 4.3 typed GDScript code and exact node hierarchies.
```
