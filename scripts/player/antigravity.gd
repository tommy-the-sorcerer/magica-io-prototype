class_name AntigravityPhysics
extends RefCounted

## Antigravity Physics System for LudusForge Hero
## Provides floaty levitating antigravity forces up to MAX_ALTITUDE.

const ANTIGRAVITY_FORCE: float = 4.5
const MAX_ALTITUDE: float = 12.0

static func apply_antigravity(body: CharacterBody3D, is_active: bool, delta: float) -> void:
	if not body:
		return
	if is_active and body.is_on_floor():
		body.velocity.y += ANTIGRAVITY_FORCE
	body.velocity.y = clampf(body.velocity.y, -MAX_ALTITUDE, MAX_ALTITUDE)
