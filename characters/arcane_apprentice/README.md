# Arcane Apprentice (Electro Blast Hero)

Self-contained character package for the Arcane Apprentice hero.

## Directory Structure
```
characters/arcane_apprentice/
├── apprentice_character.tscn       # Main character scene (hero model, animations, collision)
├── apprentice_controller.gd        # Hero controller script (controls, state machine, abilities)
├── skills/                         # Character abilities
│   ├── electro_blast.tscn          # Basic attack projectile
│   ├── electro_blast.gd            # Basic attack logic
│   ├── electro_shield.tscn         # Light Transparent Viking Celtic Round Shield
│   └── electro_shield.gd           # Shield floating mechanics, projectile block, recoil
├── vfx/                            # Specialized visual effects
│   ├── electro_dash_burst.tscn     # Lightning dash start burst
│   ├── electro_dash_ghost.tscn     # Trail afterimages during dash
│   └── electro_impact.tscn         # Impact flash and electric spark burst
└── textures/                       # Dedicated character textures
    ├── viking_celtic_light.png          # High-contrast light transparent Celtic shield
    ├── viking_celtic_light_emission.png # Subtle knot emission map
    ├── viking_celtic_shield.png         # Base cutout texture
    └── viking_celtic_shield_emission.png# Base emission texture
```

## Abilities
- **Electro Blast [LMB]**: Fires crackling ball lightning projectiles. When shield is active, fires directly from the center of the shield.
- **Lightning Dash [Q]**: High-speed dash (16.0 units/s) leaving electric afterimages.
- **Electro Shield [R]**: Launches the hovering Electro Ball from the apprentice's hand in a dynamic ballistic arc into the air, expanding into a 2.4m light transparent Viking Celtic round shield that blocks up to 5 projectiles. When it expires or breaks, the orb arcs back into the hero's hand with an elastic catch bounce.
