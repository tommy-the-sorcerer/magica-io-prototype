class_name MapAtmosphere
extends Control

## LudusForge Map Atmosphere & Storytelling Animation Controller
## Implements rich, highly realistic living environmental animations across the 2400x1350 progression map:
## 1. Eldergrove River: Flowing water currents, jumping fish, and an Armored Abyssal Leviathan
##    (matching user reference) that rises from the depths, catches the fish mid-air in a cruel bite,
##    devours it with blood/water splash, and slowly submerges.
## 2. Forgotten Graveyard: Glowing dark necrotic atmosphere, a disjointed body-parts ghost that
##    traces a burning black magic pentagram into the ground, places glowing skulls at its vertices,
##    and casts an ominous black magic ritual with swirling soul vortexes.
## 3. Frostpeak Peaks Landslides: Periodic cascading landslides and avalanches of tumbling boulders
##    and billowing snow dust rolling down the steep mountain gullies in a loop.
## 4. Mire of Sorrows Giant Serpent: A massive Titanoboa swamp snake slithering in the swamp,
##    a high-leaping fish, followed by the giant serpent erupting, constricting and swallowing the prey,
##    then diving back into the murky depths.
## 5. Cinder Wastes Volcano: Continuous billowing smoke plume plus sudden, abrupt, explosive volcanic
##    magma bursts shooting lava bombs and expanding shockwaves.
## 6. Onyx Spire Citadel: An obsidian shadow monster playing on the fortress ramparts, followed by
##    the castle door opening, the hooded Grim Reaper (with crescent scythe and lunar aura, matching
##    user reference) emerging, seizing the beast, dragging it inside, and slamming the door locked.
## 7. Soaring Flying Dragon: Majestically gliding across the sky with animated wing flapping,
##    banking turns, and dynamic ground shadow.

var anim_time: float = 0.0

# ==============================================================================
# 1. ELDERGROVE RIVER: FLOWING WATER + MYSTIC LEVIATHAN & FISH HUNT
# ==============================================================================
var leviathan_cycle_timer: float = 0.0
const LEVIATHAN_CYCLE_DURATION: float = 11.0
const LEVIATHAN_POS: Vector2 = Vector2(310, 1220)
var fish_leap_pos: Vector2 = Vector2.ZERO
var fish_is_alive: bool = true
var blood_splashes: Array = []
var river_water_offsets: Array[float] = [0.0, 0.0, 0.0]

# ==============================================================================
# 2. FORGOTTEN GRAVEYARD: GLOW IN DARK + BLACK MAGIC RITUAL
# ==============================================================================
var ritual_cycle_timer: float = 0.0
const RITUAL_CYCLE_DURATION: float = 14.0
const RITUAL_CENTER: Vector2 = Vector2(980, 1140)
const RITUAL_RADIUS: float = 48.0
var ritual_runes_drawn: float = 0.0
var ritual_skulls_placed: int = 0
var ritual_souls: Array = []

# ==============================================================================
# 3. FROSTPEAK PEAKS: MOUNTAIN LANDSLIDE / AVALANCHE
# ==============================================================================
var landslide_timer: float = 0.0
const LANDSLIDE_INTERVAL: float = 8.5
var landslide_rocks: Array = []
var avalanche_dust: Array = []
const LANDSLIDE_ORIGIN: Vector2 = Vector2(850, 175)

# ==============================================================================
# 4. MIRE OF SORROWS: GIANT SWAMP SERPENT & FISH
# ==============================================================================
var serpent_cycle_timer: float = 0.0
const SERPENT_CYCLE_DURATION: float = 12.0
const SERPENT_BASE_POS: Vector2 = Vector2(1620, 840)
var swamp_fish_pos: Vector2 = Vector2.ZERO
var swamp_fish_alive: bool = true
var serpent_coil_points: Array[Vector2] = []

# ==============================================================================
# 5. CINDER WASTES: ABRUPT RANDOM VOLCANO BURSTS
# ==============================================================================
var burst_timer: float = 0.0
var next_burst_delay: float = 4.0
var burst_active: bool = false
var burst_progress: float = 0.0
var burst_shockwave_radius: float = 0.0
var lava_bombs: Array = []
const VOLCANO_CRATER: Vector2 = Vector2(1735, 235)
const SECONDARY_VENT: Vector2 = Vector2(1655, 305)
var volcano_smoke: Array = []
const MAX_SMOKE_PUFFS: int = 38
var volcano_embers: Array = []
const MAX_EMBERS: int = 30

# ==============================================================================
# 6. ONYX SPIRE: OBSIDIAN MONSTER & THE GRIM REAPER
# ==============================================================================
var reaper_cycle_timer: float = 0.0
const REAPER_CYCLE_DURATION: float = 15.0
const CITADEL_DOOR_POS: Vector2 = Vector2(2140, 240)
var obsidian_monster_pos: Vector2 = Vector2(2100, 270)
var door_open_ratio: float = 0.0 # 0.0 to 1.0

# ==============================================================================
# 7. SOARING FLYING DRAGON
# ==============================================================================
var dragon_t: float = 0.0
var dragon_speed: float = 0.035
var dragon_pos: Vector2 = Vector2.ZERO
var dragon_heading: float = 0.0
var wing_phase: float = 0.0
var dragon_trail_particles: Array = []

const DRAGON_PATH: Array[Vector2] = [
	Vector2(2180, 220), Vector2(1920, 160), Vector2(1580, 130),
	Vector2(1220, 110), Vector2(950, 180), Vector2(1150, 320),
	Vector2(1480, 360), Vector2(1820, 310), Vector2(2120, 270)
]

# Environmental background details
var snowflakes: Array = []
const ICE_BOUNDS: Rect2 = Rect2(460, 80, 720, 440)
var ice_sparkles: Array = []
var fireflies: Array = []
const FOREST_BOUNDS: Rect2 = Rect2(120, 920, 560, 400)
var graveyard_fog: Array = []
var lightning_timer: float = 0.0
var lightning_flash_alpha: float = 0.0
var lightning_bolt_points: Array[Vector2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_volcano_smoke()
	_init_snowflakes()
	_init_ice_sparkles()
	_init_fireflies()
	_init_graveyard_fog()

func _init_volcano_smoke() -> void:
	for i in range(MAX_SMOKE_PUFFS):
		var is_secondary := (randf() < 0.25)
		var origin := SECONDARY_VENT if is_secondary else VOLCANO_CRATER
		volcano_smoke.append({
			"origin": origin,
			"pos": origin + Vector2(randf_range(-15, 15), randf_range(-10, 10)),
			"vel": Vector2(randf_range(-8, -2), randf_range(-35, -55)),
			"radius": randf_range(16.0, 24.0),
			"max_radius": randf_range(65.0, 95.0),
			"age": randf_range(0.0, 4.0),
			"lifetime": randf_range(3.5, 4.8),
			"rot": randf_range(0, TAU),
			"rot_speed": randf_range(-0.6, 0.6)
		})
	for i in range(MAX_EMBERS):
		volcano_embers.append({
			"pos": VOLCANO_CRATER + Vector2(randf_range(-12, 12), randf_range(-6, 6)),
			"vel": Vector2(randf_range(-14, 6), randf_range(-60, -110)),
			"life": randf_range(0.0, 1.6),
			"max_life": randf_range(1.2, 2.0),
			"size": randf_range(2.0, 4.5)
		})

func _init_snowflakes() -> void:
	for i in range(65):
		snowflakes.append({
			"pos": Vector2(
				randf_range(ICE_BOUNDS.position.x, ICE_BOUNDS.end.x),
				randf_range(ICE_BOUNDS.position.y, ICE_BOUNDS.end.y)
			),
			"vel": Vector2(randf_range(12.0, 28.0), randf_range(25.0, 50.0)),
			"size": randf_range(1.5, 4.0),
			"alpha": randf_range(0.4, 0.9),
			"sway_phase": randf_range(0, TAU)
		})

func _init_ice_sparkles() -> void:
	var points: Array[Vector2] = [
		Vector2(580, 240), Vector2(660, 190), Vector2(740, 150),
		Vector2(830, 170), Vector2(920, 220), Vector2(1010, 260),
		Vector2(620, 340), Vector2(760, 290), Vector2(880, 330)
	]
	for pt in points:
		ice_sparkles.append({
			"pos": pt + Vector2(randf_range(-15, 15), randf_range(-10, 10)),
			"flare_timer": randf_range(0.0, 4.0),
			"flare_period": randf_range(2.5, 5.0),
			"flare_size": randf_range(14.0, 22.0)
		})

func _init_fireflies() -> void:
	for i in range(25):
		fireflies.append({
			"base_pos": Vector2(
				randf_range(FOREST_BOUNDS.position.x, FOREST_BOUNDS.end.x),
				randf_range(FOREST_BOUNDS.position.y, FOREST_BOUNDS.end.y)
			),
			"offset": Vector2.ZERO,
			"phase_x": randf_range(0, TAU),
			"phase_y": randf_range(0, TAU),
			"speed_x": randf_range(0.8, 1.8),
			"speed_y": randf_range(0.6, 1.4),
			"glow_phase": randf_range(0, TAU),
			"radius": randf_range(2.0, 3.8)
		})

func _init_graveyard_fog() -> void:
	for i in range(6):
		graveyard_fog.append({
			"pos": Vector2(
				randf_range(900, 1100),
				randf_range(1050, 1220)
			),
			"size": Vector2(randf_range(100, 180), randf_range(30, 50)),
			"speed": randf_range(8.0, 15.0),
			"alpha": randf_range(0.18, 0.32)
		})

# ==============================================================================
# MAIN PROCESS LOOP
# ==============================================================================

func _process(delta: float) -> void:
	anim_time += delta
	
	_update_dragon(delta)
	_update_eldergrove_leviathan(delta)
	_update_graveyard_ritual(delta)
	_update_frostpeak_landslides(delta)
	_update_mire_serpent(delta)
	_update_volcano_bursts(delta)
	_update_onyx_reaper(delta)
	
	_update_background_elements(delta)
	queue_redraw()

func _update_background_elements(delta: float) -> void:
	for s in snowflakes:
		s.sway_phase += delta * 2.0
		var sway := sin(s.sway_phase) * 14.0
		s.pos += (s.vel + Vector2(sway, 0.0)) * delta
		if not ICE_BOUNDS.has_point(s.pos):
			s.pos.y = ICE_BOUNDS.position.y + randf_range(0, 20)
			s.pos.x = randf_range(ICE_BOUNDS.position.x, ICE_BOUNDS.end.x)
			
	for sp in ice_sparkles:
		sp.flare_timer += delta
		if sp.flare_timer >= sp.flare_period:
			sp.flare_timer = 0.0
			sp.flare_period = randf_range(2.5, 5.0)
			
	for f in fireflies:
		f.phase_x += delta * f.speed_x
		f.phase_y += delta * f.speed_y
		f.offset = Vector2(sin(f.phase_x) * 30.0, cos(f.phase_y) * 22.0)
		f.glow_phase += delta * 3.0
		
	for g in graveyard_fog:
		g.pos.x += g.speed * delta
		if g.pos.x > 1150:
			g.pos.x = 850
			g.pos.y = randf_range(1050, 1220)
			
	lightning_timer += delta
	if lightning_timer >= 6.5:
		lightning_timer = 0.0
		lightning_flash_alpha = 0.85
		_generate_lightning_bolt()
	if lightning_flash_alpha > 0.0:
		lightning_flash_alpha = maxf(0.0, lightning_flash_alpha - delta * 3.5)

func _generate_lightning_bolt() -> void:
	lightning_bolt_points.clear()
	var start_pt := Vector2(randf_range(2050, 2220), randf_range(40, 80))
	var end_pt := Vector2(randf_range(2100, 2200), randf_range(220, 280))
	var curr := start_pt
	lightning_bolt_points.append(curr)
	for i in range(7):
		var t := float(i + 1) / 7.0
		var target := start_pt.lerp(end_pt, t)
		target.x += randf_range(-22, 22)
		lightning_bolt_points.append(target)

func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	return q0.lerp(q1, t)

# ==============================================================================
# 1. ELDERGROVE RIVER: LEVIATHAN & FISH ANIMATION LOGIC
# ==============================================================================
func _update_eldergrove_leviathan(delta: float) -> void:
	leviathan_cycle_timer += delta
	if leviathan_cycle_timer >= LEVIATHAN_CYCLE_DURATION:
		leviathan_cycle_timer = 0.0
		fish_is_alive = true
		blood_splashes.clear()
		
	# Water river flow drift
	for i in range(3):
		river_water_offsets[i] = fmod(river_water_offsets[i] + delta * (22.0 + i * 8.0), 80.0)
		
	# Fish leaping arc between 3.5s and 5.5s
	if leviathan_cycle_timer >= 3.5 and leviathan_cycle_timer < 5.8:
		var ft := (leviathan_cycle_timer - 3.5) / 2.3
		var start_p := LEVIATHAN_POS + Vector2(-45, 30)
		var end_p := LEVIATHAN_POS + Vector2(25, -20)
		var mid_p := (start_p + end_p) * 0.5 + Vector2(0, -65) # High arc
		fish_leap_pos = _quad_bezier(start_p, mid_p, end_p, ft)
		
		# Leviathan jaws snap at ft ~ 0.72 (time ~ 5.1s)
		if ft >= 0.72 and fish_is_alive:
			fish_is_alive = false
			# Spawn blood splash particles
			for k in range(16):
				blood_splashes.append({
					"pos": fish_leap_pos,
					"vel": Vector2(randf_range(-35, 35), randf_range(-45, 15)),
					"life": 0.0,
					"max_life": randf_range(0.8, 1.4),
					"size": randf_range(2.5, 5.0)
				})
				
	# Update blood splash particles
	for i in range(blood_splashes.size() - 1, -1, -1):
		var b: Dictionary = blood_splashes[i]
		b.life += delta
		b.pos += b.vel * delta
		b.vel.y += 60.0 * delta # Gravity
		if b.life >= b.max_life:
			blood_splashes.remove_at(i)

# ==============================================================================
# 2. GRAVEYARD: BLACK MAGIC RITUAL ANIMATION LOGIC
# ==============================================================================
func _update_graveyard_ritual(delta: float) -> void:
	ritual_cycle_timer += delta
	if ritual_cycle_timer >= RITUAL_CYCLE_DURATION:
		ritual_cycle_timer = 0.0
		ritual_souls.clear()
		
	# Phase 1: Draw burning pentagram design (0 to 4s)
	if ritual_cycle_timer < 4.0:
		ritual_runes_drawn = clampf(ritual_cycle_timer / 3.8, 0.0, 1.0)
		ritual_skulls_placed = 0
	# Phase 2: Place glowing skulls at 5 star points (4s to 7s)
	elif ritual_cycle_timer < 7.0:
		ritual_runes_drawn = 1.0
		ritual_skulls_placed = clampi(int((ritual_cycle_timer - 4.0) / 0.6) + 1, 0, 5)
	# Phase 3: Black Magic Ritual (7s to 12s)
	else:
		ritual_runes_drawn = 1.0
		ritual_skulls_placed = 5
		# Spawn rising tormented souls
		if randf() < 0.3:
			ritual_souls.append({
				"pos": RITUAL_CENTER + Vector2(randf_range(-35, 35), randf_range(-35, 35)),
				"vel": Vector2(randf_range(-15, 15), randf_range(-30, -55)),
				"life": 0.0,
				"max_life": randf_range(1.5, 2.5),
				"rot": randf_range(0, TAU)
			})
			
	for i in range(ritual_souls.size() - 1, -1, -1):
		var s: Dictionary = ritual_souls[i]
		s.life += delta
		s.pos += s.vel * delta
		s.rot += delta * 3.0
		if s.life >= s.max_life:
			ritual_souls.remove_at(i)

# ==============================================================================
# 3. FROSTPEAK PEAKS: MOUNTAIN LANDSLIDE ANIMATION LOGIC
# ==============================================================================
func _update_frostpeak_landslides(delta: float) -> void:
	landslide_timer += delta
	if landslide_timer >= LANDSLIDE_INTERVAL:
		landslide_timer = 0.0
		# Trigger new massive landslide
		for i in range(26):
			landslide_rocks.append({
				"pos": LANDSLIDE_ORIGIN + Vector2(randf_range(-35, 35), randf_range(-15, 15)),
				"vel": Vector2(randf_range(15, 45), randf_range(35, 75)),
				"size": randf_range(3.5, 8.5),
				"rot": randf_range(0, TAU),
				"rot_speed": randf_range(-8.0, 8.0),
				"life": 0.0,
				"max_life": randf_range(3.2, 4.8)
			})
		for j in range(35):
			avalanche_dust.append({
				"pos": LANDSLIDE_ORIGIN + Vector2(randf_range(-25, 25), randf_range(0, 30)),
				"vel": Vector2(randf_range(10, 35), randf_range(25, 55)),
				"radius": randf_range(12.0, 20.0),
				"max_radius": randf_range(35.0, 55.0),
				"life": 0.0,
				"max_life": randf_range(3.5, 5.0)
			})
			
	for i in range(landslide_rocks.size() - 1, -1, -1):
		var r: Dictionary = landslide_rocks[i]
		r.life += delta
		r.pos += r.vel * delta
		r.vel.y += 25.0 * delta # Gravity
		r.rot += r.rot_speed * delta
		if r.life >= r.max_life:
			landslide_rocks.remove_at(i)
			
	for j in range(avalanche_dust.size() - 1, -1, -1):
		var d: Dictionary = avalanche_dust[j]
		d.life += delta
		d.pos += d.vel * delta
		if d.life >= d.max_life:
			avalanche_dust.remove_at(j)

# ==============================================================================
# 4. MIRE OF SORROWS: GIANT SWAMP SERPENT & FISH ANIMATION LOGIC
# ==============================================================================
func _update_mire_serpent(delta: float) -> void:
	serpent_cycle_timer += delta
	if serpent_cycle_timer >= SERPENT_CYCLE_DURATION:
		serpent_cycle_timer = 0.0
		swamp_fish_alive = true
		
	# High-jumping fish in swamp (between 4.0s and 6.2s)
	if serpent_cycle_timer >= 4.0 and serpent_cycle_timer < 6.4:
		var sft := (serpent_cycle_timer - 4.0) / 2.4
		var start_f := SERPENT_BASE_POS + Vector2(-35, 45)
		var end_f := SERPENT_BASE_POS + Vector2(35, 10)
		var peak_f := (start_f + end_f) * 0.5 + Vector2(0, -95) # High leap!
		swamp_fish_pos = _quad_bezier(start_f, peak_f, end_f, sft)
		
		# Snake strikes and swallows at sft ~ 0.65
		if sft >= 0.65 and swamp_fish_alive:
			swamp_fish_alive = false

# ==============================================================================
# 5. CINDER WASTES: ABRUPT RANDOM VOLCANO BURSTS LOGIC
# ==============================================================================
func _update_volcano_bursts(delta: float) -> void:
	burst_timer += delta
	if burst_timer >= next_burst_delay:
		burst_timer = 0.0
		next_burst_delay = randf_range(4.0, 7.5)
		burst_active = true
		burst_progress = 0.0
		burst_shockwave_radius = 10.0
		
		# Launch high-velocity incandescent lava bombs
		for i in range(15):
			var angle := randf_range(-PI * 0.85, -PI * 0.15)
			var spd := randf_range(110.0, 220.0)
			lava_bombs.append({
				"pos": VOLCANO_CRATER + Vector2(randf_range(-8, 8), randf_range(-4, 4)),
				"vel": Vector2(cos(angle) * spd, sin(angle) * spd),
				"life": 0.0,
				"max_life": randf_range(2.0, 3.2),
				"size": randf_range(3.5, 6.5)
			})
			
	if burst_active:
		burst_progress += delta * 2.5
		burst_shockwave_radius += delta * 180.0
		if burst_progress >= 1.0:
			burst_active = false
			
	for i in range(lava_bombs.size() - 1, -1, -1):
		var b: Dictionary = lava_bombs[i]
		b.life += delta
		b.pos += b.vel * delta
		b.vel.y += 120.0 * delta # Heavy gravity arc
		if b.life >= b.max_life:
			lava_bombs.remove_at(i)
			
	# Update regular smoke plume
	for p in volcano_smoke:
		p.age += delta
		p.pos += p.vel * delta
		p.rot += p.rot_speed * delta
		if p.age >= p.lifetime:
			p.age = 0.0
			p.pos = p.origin + Vector2(randf_range(-12, 12), randf_range(-6, 6))
			p.vel = Vector2(randf_range(-10, -2), randf_range(-35, -55))
			p.radius = randf_range(16.0, 24.0)
			
	for e in volcano_embers:
		e.life += delta
		e.pos += e.vel * delta
		e.vel.x += sin(anim_time * 6.0 + e.life) * 12.0 * delta
		if e.life >= e.max_life:
			e.life = 0.0
			e.pos = VOLCANO_CRATER + Vector2(randf_range(-12, 12), randf_range(-6, 6))
			e.vel = Vector2(randf_range(-14, 6), randf_range(-60, -110))

# ==============================================================================
# 6. ONYX SPIRE: OBSIDIAN MONSTER & GRIM REAPER LOGIC
# ==============================================================================
func _update_onyx_reaper(delta: float) -> void:
	reaper_cycle_timer += delta
	if reaper_cycle_timer >= REAPER_CYCLE_DURATION:
		reaper_cycle_timer = 0.0
		
	# Phase 1: Obsidian monster leaps & plays (0 to 5s)
	if reaper_cycle_timer < 5.0:
		door_open_ratio = 0.0
		var hop := absf(sin(reaper_cycle_timer * 6.0)) * 14.0
		var side := cos(reaper_cycle_timer * 2.5) * 28.0
		obsidian_monster_pos = CITADEL_DOOR_POS + Vector2(-55 + side, 40 - hop)
	# Phase 2: Citadel door slowly creaks open (5s to 7s)
	elif reaper_cycle_timer < 7.0:
		door_open_ratio = (reaper_cycle_timer - 5.0) / 2.0
		obsidian_monster_pos = CITADEL_DOOR_POS + Vector2(-35, 40)
	# Phase 3: Grim Reaper steps out (7s to 9.5s)
	elif reaper_cycle_timer < 9.5:
		door_open_ratio = 1.0
		# Beast notices and cowers
		obsidian_monster_pos = CITADEL_DOOR_POS + Vector2(-28, 42)
	# Phase 4: Reaper seizes and drags beast inside (9.5s to 12s)
	elif reaper_cycle_timer < 12.0:
		door_open_ratio = 1.0
		var dt := (reaper_cycle_timer - 9.5) / 2.5
		obsidian_monster_pos = (CITADEL_DOOR_POS + Vector2(-28, 42)).lerp(CITADEL_DOOR_POS + Vector2(10, 15), dt)
	# Phase 5: Door slams shut & locks (12s to 15s)
	else:
		door_open_ratio = maxf(0.0, 1.0 - (reaper_cycle_timer - 12.0) * 4.0)

# ==============================================================================
# 7. SOARING FLYING DRAGON LOGIC
# ==============================================================================
func _update_dragon(delta: float) -> void:
	dragon_t += delta * dragon_speed
	if dragon_t >= 1.0:
		dragon_t -= 1.0
		
	var count := DRAGON_PATH.size()
	var total_f := dragon_t * float(count)
	var idx := int(floor(total_f)) % count
	var next_idx := (idx + 1) % count
	var frac := total_f - float(int(floor(total_f)))
	
	var p0 := DRAGON_PATH[(idx - 1 + count) % count]
	var p1 := DRAGON_PATH[idx]
	var p2 := DRAGON_PATH[next_idx]
	var p3 := DRAGON_PATH[(next_idx + 1) % count]
	
	dragon_pos = p1.cubic_interpolate(p2, p0, p3, frac)
	var next_pos := p1.cubic_interpolate(p2, p0, p3, clampf(frac + 0.02, 0.0, 1.0))
	var forward := (next_pos - dragon_pos).normalized()
	dragon_heading = forward.angle()
	wing_phase += delta * 4.2
	
	if randf() < 0.35:
		dragon_trail_particles.append({
			"pos": dragon_pos - forward * 24.0 + Vector2(randf_range(-4, 4), randf_range(-4, 4)),
			"vel": -forward * randf_range(10, 25) + Vector2(0, randf_range(-5, -15)),
			"age": 0.0,
			"lifetime": randf_range(0.6, 1.2),
			"col": Color(1.0, randf_range(0.3, 0.8), 0.1)
		})
		
	for i in range(dragon_trail_particles.size() - 1, -1, -1):
		var p: Dictionary = dragon_trail_particles[i]
		p.age += delta
		p.pos += p.vel * delta
		if p.age >= p.lifetime:
			dragon_trail_particles.remove_at(i)

# ==============================================================================
# PROCEDURAL DRAWING OF ALL CINEMATIC SCENES
# ==============================================================================

func _draw() -> void:
	_draw_eldergrove_river_and_leviathan()
	_draw_graveyard_black_magic_ritual()
	_draw_frostpeak_landslides()
	_draw_mire_serpent_and_fish()
	_draw_volcano_bursts_and_smoke()
	_draw_onyx_spire_and_reaper()
	_draw_ambient_fx()
	_draw_flying_dragon()

func _draw_ambient_fx() -> void:
	# Snowflakes
	for s in snowflakes:
		draw_circle(s.pos, float(s.size), Color(0.95, 0.98, 1.0, float(s.alpha)))
	# Glacier Sparkles
	for sp in ice_sparkles:
		var flare_norm: float = float(sp.flare_timer) / 0.7
		if flare_norm <= 1.0:
			var flare_alpha := sin(flare_norm * PI)
			var f_size: float = float(sp.flare_size) * flare_alpha
			var p: Vector2 = sp.pos
			draw_line(p - Vector2(f_size, 0), p + Vector2(f_size, 0), Color(1, 1, 1, flare_alpha * 0.95), 2.2)
			draw_line(p - Vector2(0, f_size), p + Vector2(0, f_size), Color(1, 1, 1, flare_alpha * 0.95), 2.2)
			draw_circle(p, f_size * 0.35, Color(0.4, 0.9, 1, flare_alpha * 0.8))
	# Fireflies
	for f in fireflies:
		var p: Vector2 = f.base_pos + f.offset
		var pulse := (sin(f.glow_phase) * 0.5 + 0.5)
		draw_circle(p, float(f.radius) * 3.0, Color(0.6, 1.0, 0.25, 0.35 + pulse * 0.35))
		draw_circle(p, float(f.radius), Color(1.0, 1.0, 0.7, 0.8 + pulse * 0.2))
	# Citadel Lightning
	if lightning_flash_alpha > 0.0:
		draw_rect(Rect2(1920, 40, 480, 420), Color(0.75, 0.85, 1.0, lightning_flash_alpha * 0.35))
		if lightning_bolt_points.size() > 1:
			for i in range(lightning_bolt_points.size() - 1):
				draw_line(lightning_bolt_points[i], lightning_bolt_points[i + 1], Color(0.5, 0.75, 1.0, lightning_flash_alpha), 5.5)
				draw_line(lightning_bolt_points[i], lightning_bolt_points[i + 1], Color(1.0, 1.0, 1.0, lightning_flash_alpha), 2.2)

# ------------------------------------------------------------------------------
# 1. DRAW ELDERGROVE: FLOWING WATER + MYSTIC LEVIATHAN (Matching Image)
# ------------------------------------------------------------------------------
func _draw_eldergrove_river_and_leviathan() -> void:
	# 1. Flowing River Water Waves
	var river_pts := [Vector2(240, 1340), Vector2(270, 1260), Vector2(330, 1200), Vector2(380, 1140)]
	for i in range(river_pts.size() - 1):
		var pA: Vector2 = river_pts[i]
		var pB: Vector2 = river_pts[i + 1]
		var flow_dir := (pB - pA).normalized()
		var wave_offset := flow_dir * river_water_offsets[i % 3]
		draw_line(pA + wave_offset, pB + wave_offset, Color(0.2, 0.65, 0.85, 0.4), 8.0)
		draw_line(pA + wave_offset * 0.7, pB + wave_offset * 0.7, Color(0.8, 0.95, 1.0, 0.6), 2.5)
		
	# 2. Leaping Fish (when active)
	if fish_is_alive and leviathan_cycle_timer >= 3.5 and leviathan_cycle_timer < 5.8:
		# Fish body
		draw_circle(fish_leap_pos, 4.5, Color(0.35, 0.85, 0.75))
		draw_line(fish_leap_pos, fish_leap_pos - Vector2(6, -3), Color(0.2, 0.6, 0.5), 2.0) # Tail
		draw_circle(fish_leap_pos + Vector2(2, -1), 1.2, Color(1, 1, 1)) # Eye
		# Water spray
		draw_circle(fish_leap_pos + Vector2(randf_range(-3, 3), randf_range(2, 6)), 2.0, Color(0.8, 0.95, 1.0, 0.7))
		
	# 3. Mystic Armored Leviathan (Rising & Striking)
	var rise_factor := 0.0
	if leviathan_cycle_timer >= 4.6 and leviathan_cycle_timer < 8.2:
		rise_factor = sin(((leviathan_cycle_timer - 4.6) / 3.6) * PI)
		
	var lp := LEVIATHAN_POS + Vector2(0, (1.0 - rise_factor) * 35.0)
	
	# Deep underwater cyan glow (always subtly visible)
	var deep_glow := (sin(anim_time * 3.0) * 0.5 + 0.5)
	draw_circle(LEVIATHAN_POS + Vector2(0, 10), 28.0 + deep_glow * 8.0, Color(0.05, 0.8, 0.9, 0.25 + deep_glow * 0.2))
	
	if rise_factor > 0.05:
		# Large armored head (steely dark slate blue with armored carapace)
		var head_poly := PackedVector2Array([
			lp + Vector2(0, -32 * rise_factor),  # Snout
			lp + Vector2(22, -18 * rise_factor), # Upper jaw
			lp + Vector2(28, 4),                 # Cheek armor plate
			lp + Vector2(16, 22),                # Throat
			lp + Vector2(-16, 22),
			lp + Vector2(-28, 4),
			lp + Vector2(-22, -18 * rise_factor)
		])
		draw_colored_polygon(head_poly, Color(0.1, 0.15, 0.22, rise_factor))
		draw_polyline(head_poly, Color(0.25, 0.45, 0.6, rise_factor), 2.2)
		
		# Coral crest spines along the head (matching reference image)
		draw_line(lp + Vector2(-16, -18 * rise_factor), lp + Vector2(-26, -34 * rise_factor), Color(0.3, 0.8, 0.7, rise_factor), 3.0)
		draw_line(lp + Vector2(0, -22 * rise_factor), lp + Vector2(0, -42 * rise_factor), Color(0.3, 0.85, 0.75, rise_factor), 3.5)
		draw_line(lp + Vector2(16, -18 * rise_factor), lp + Vector2(26, -34 * rise_factor), Color(0.3, 0.8, 0.7, rise_factor), 3.0)
		
		# Multiple glowing cyan eyes (as shown in reference image)
		var eye_col := Color(0.15, 0.95, 1.0, rise_factor)
		draw_circle(lp + Vector2(-12, -10 * rise_factor), 2.8, eye_col)
		draw_circle(lp + Vector2(-6, -16 * rise_factor), 2.2, eye_col)
		draw_circle(lp + Vector2(6, -16 * rise_factor), 2.2, eye_col)
		draw_circle(lp + Vector2(12, -10 * rise_factor), 2.8, eye_col)
		
		# Bioluminescent ventral nodes
		draw_circle(lp + Vector2(-16, 8), 1.8, eye_col * 0.8)
		draw_circle(lp + Vector2(16, 8), 1.8, eye_col * 0.8)
		
		# Ferocious jaws & needle fangs (snapping open when rising)
		if leviathan_cycle_timer >= 4.9 and leviathan_cycle_timer < 6.8:
			draw_line(lp + Vector2(-10, -18 * rise_factor), lp + Vector2(-12, -26 * rise_factor), Color(1, 1, 1, rise_factor), 1.8)
			draw_line(lp + Vector2(-4, -20 * rise_factor), lp + Vector2(-4, -28 * rise_factor), Color(1, 1, 1, rise_factor), 1.8)
			draw_line(lp + Vector2(4, -20 * rise_factor), lp + Vector2(4, -28 * rise_factor), Color(1, 1, 1, rise_factor), 1.8)
			draw_line(lp + Vector2(10, -18 * rise_factor), lp + Vector2(12, -26 * rise_factor), Color(1, 1, 1, rise_factor), 1.8)
			
		# Expanding water displacement ring ripples
		draw_arc(LEVIATHAN_POS, 32.0 * rise_factor, 0, TAU, 24, Color(0.7, 0.9, 1.0, (1.0 - rise_factor) * 0.8), 2.0)
		
	# Blood splash particles
	for b in blood_splashes:
		var t: float = float(b.life) / float(b.max_life)
		var a: float = (1.0 - t) * 0.9
		draw_circle(b.pos, float(b.size) * (1.0 - t * 0.4), Color(0.85, 0.1, 0.15, a))

# ------------------------------------------------------------------------------
# 2. DRAW GRAVEYARD: GLOW IN DARK + BLACK MAGIC RITUAL PENTAGRAM
# ------------------------------------------------------------------------------
func _draw_graveyard_black_magic_ritual() -> void:
	# Ambient Dark Necrotic Glow over graveyard
	var necro_pulse := (sin(anim_time * 2.0) * 0.5 + 0.5)
	draw_circle(RITUAL_CENTER, 85.0 + necro_pulse * 15.0, Color(0.35, 0.08, 0.55, 0.28 + necro_pulse * 0.18))
	draw_circle(RITUAL_CENTER, 45.0, Color(0.15, 0.85, 0.45, 0.18 + necro_pulse * 0.12))
	
	# Draw glowing black magic pentagram
	if ritual_runes_drawn > 0.0:
		var magic_col := Color(0.75, 0.2, 0.98, ritual_runes_drawn * 0.95)
		var core_col := Color(0.3, 1.0, 0.6, ritual_runes_drawn * 0.85)
		
		# Outer boundary circle
		draw_arc(RITUAL_CENTER, RITUAL_RADIUS, 0, TAU * ritual_runes_drawn, 36, magic_col, 2.5)
		draw_arc(RITUAL_CENTER, RITUAL_RADIUS * 0.82, 0, TAU * ritual_runes_drawn, 36, core_col, 1.4)
		
		# 5 Star points
		var star_pts: Array[Vector2] = []
		for i in range(5):
			var a: float = -PI * 0.5 + float(i) * (TAU / 5.0)
			star_pts.append(RITUAL_CENTER + Vector2(cos(a), sin(a)) * RITUAL_RADIUS * 0.82)
			
		# Interconnecting pentagram lines
		var order := [0, 2, 4, 1, 3, 0]
		for i in range(order.size() - 1):
			var idxA: int = order[i]
			var idxB: int = order[i + 1]
			if float(i) / 5.0 <= ritual_runes_drawn:
				draw_line(star_pts[idxA], star_pts[idxB], magic_col, 2.2)
				draw_line(star_pts[idxA], star_pts[idxB], core_col, 1.0)
				
		# Skulls placed at vertices
		for s_idx in range(ritual_skulls_placed):
			var pt: Vector2 = star_pts[s_idx]
			# Skull cranium & jaw
			draw_circle(pt, 5.2, Color(0.9, 0.92, 0.85, 0.95))
			draw_rect(Rect2(pt + Vector2(-3, 2), Vector2(6, 4)), Color(0.85, 0.85, 0.8, 0.95))
			# Glowing balefire eye sockets
			var skull_eye := Color(0.2, 1.0, 0.5, 0.95)
			draw_circle(pt + Vector2(-2, -0.5), 1.2, skull_eye)
			draw_circle(pt + Vector2(2, -0.5), 1.2, skull_eye)
			
	# Disjointed Body Parts Ghost (floating above ritual)
	var ghost_hover := sin(anim_time * 3.5) * 6.0
	var gp := RITUAL_CENTER + Vector2(0, -32 + ghost_hover)
	
	# Spectral horned skull
	draw_circle(gp, 7.5, Color(0.7, 0.8, 0.95, 0.85))
	draw_circle(gp + Vector2(-3, -1), 1.8, Color(0.2, 1.0, 0.6))
	draw_circle(gp + Vector2(3, -1), 1.8, Color(0.2, 1.0, 0.6))
	# Disjointed floating skeletal arms/hands
	var arm_swing := sin(anim_time * 4.0) * 8.0
	draw_line(gp + Vector2(-16, 10), gp + Vector2(-22, 22 + arm_swing), Color(0.75, 0.85, 1.0, 0.8), 2.5)
	draw_line(gp + Vector2(16, 10), gp + Vector2(22, 22 - arm_swing), Color(0.75, 0.85, 1.0, 0.8), 2.5)
	# Floating spine & tattered purple shroud
	draw_line(gp + Vector2(0, 8), gp + Vector2(0, 24), Color(0.6, 0.7, 0.9, 0.7), 3.0)
	draw_circle(gp + Vector2(0, 28), 5.0, Color(0.5, 0.15, 0.75, 0.45))
	
	# Swirling Tormented Souls during ritual apex
	for soul in ritual_souls:
		var t: float = float(soul.life) / float(soul.max_life)
		var a: float = (1.0 - t) * 0.8
		var col := Color(0.4, 0.9, 0.7, a) if fmod(soul.life, 0.4) < 0.2 else Color(0.75, 0.3, 1.0, a)
		draw_circle(soul.pos, 4.0 * (1.0 - t * 0.4), col)
		draw_line(soul.pos, soul.pos - soul.vel * 0.18, col * 0.8, 1.8)

# ------------------------------------------------------------------------------
# 3. DRAW FROSTPEAK PEAKS: MOUNTAIN LANDSLIDE & AVALANCHE
# ------------------------------------------------------------------------------
func _draw_frostpeak_landslides() -> void:
	# Billowing avalanche powder dust clouds
	for d in avalanche_dust:
		var t: float = float(d.life) / float(d.max_life)
		var r: float = lerpf(float(d.radius), float(d.max_radius), t)
		var a: float = (1.0 - t) * 0.55
		draw_circle(d.pos, r, Color(0.9, 0.94, 1.0, a))
		
	# Tumbling landslide boulders
	for r in landslide_rocks:
		var t: float = float(r.life) / float(r.max_life)
		var a: float = (1.0 - t * 0.3)
		var sz: float = float(r.size)
		var xform := Transform2D(float(r.rot), r.pos)
		var rock_poly := PackedVector2Array([
			xform * Vector2(-sz, -sz * 0.6),
			xform * Vector2(sz * 0.4, -sz),
			xform * Vector2(sz, -sz * 0.2),
			xform * Vector2(sz * 0.8, sz * 0.8),
			xform * Vector2(-sz * 0.6, sz)
		])
		draw_colored_polygon(rock_poly, Color(0.35, 0.38, 0.42, a))
		draw_polyline(rock_poly, Color(0.55, 0.58, 0.62, a), 1.2)

# ------------------------------------------------------------------------------
# 4. DRAW MIRE OF SORROWS: GIANT SWAMP SERPENT & FISH
# ------------------------------------------------------------------------------
func _draw_mire_serpent_and_fish() -> void:
	# High-jumping golden swamp catfish
	if swamp_fish_alive and serpent_cycle_timer >= 4.0 and serpent_cycle_timer < 6.4:
		draw_circle(swamp_fish_pos, 5.0, Color(0.95, 0.8, 0.2))
		draw_line(swamp_fish_pos, swamp_fish_pos - Vector2(8, -4), Color(0.8, 0.6, 0.1), 2.2)
		draw_circle(swamp_fish_pos + Vector2(2, -1), 1.2, Color(0, 0, 0))
		draw_circle(swamp_fish_pos + Vector2(randf_range(-4, 4), randf_range(2, 8)), 2.5, Color(0.5, 0.9, 0.6, 0.6))
		
	# Giant Serpent undulating through swamp
	var snake_body_pts: Array[Vector2] = []
	var num_segments := 14
	var wave_time := anim_time * 3.5
	var snake_head_lift := 0.0
	
	if serpent_cycle_timer >= 4.8 and serpent_cycle_timer < 7.2:
		snake_head_lift = sin(((serpent_cycle_timer - 4.8) / 2.4) * PI) * 55.0
		
	for i in range(num_segments):
		var seg_t := float(i) * 16.0
		var undulation := sin(wave_time - float(i) * 0.55) * 18.0
		var seg_pos := SERPENT_BASE_POS + Vector2(-seg_t * 1.2, undulation)
		if i == 0:
			seg_pos.y -= snake_head_lift # Head lunges up to strike!
		elif i < 4:
			seg_pos.y -= snake_head_lift * (1.0 - float(i) * 0.25)
		snake_body_pts.append(seg_pos)
		
	# Draw massive snake coils
	for i in range(snake_body_pts.size() - 1, 0, -1):
		var pA: Vector2 = snake_body_pts[i]
		var radius := (14.0 - float(i) * 0.7)
		draw_circle(pA, radius, Color(0.12, 0.24, 0.15))
		draw_circle(pA + Vector2(0, radius * 0.4), radius * 0.55, Color(0.35, 0.45, 0.2)) # Belly
		
	# Giant Serpent Head with unhinged jaws
	var head_p: Vector2 = snake_body_pts[0]
	draw_circle(head_p, 16.0, Color(0.1, 0.22, 0.14))
	# Glowing yellow venomous eyes
	draw_circle(head_p + Vector2(6, -6), 3.2, Color(1.0, 0.9, 0.1))
	draw_circle(head_p + Vector2(6, 6), 3.2, Color(1.0, 0.9, 0.1))
	# Forked tongue
	if fmod(anim_time, 1.2) < 0.4:
		draw_line(head_p + Vector2(14, 0), head_p + Vector2(24, -4), Color(0.9, 0.1, 0.15), 1.8)
		draw_line(head_p + Vector2(14, 0), head_p + Vector2(24, 4), Color(0.9, 0.1, 0.15), 1.8)

# ------------------------------------------------------------------------------
# 5. DRAW CINDER WASTES: ABRUPT RANDOM VOLCANO BURSTS & SMOKE
# ------------------------------------------------------------------------------
func _draw_volcano_bursts_and_smoke() -> void:
	# Standard smoke plume
	for p in volcano_smoke:
		var t: float = float(p.age) / float(p.lifetime)
		var r: float = lerpf(float(p.radius), float(p.max_radius), t)
		var alpha: float = (1.0 - t) * 0.52
		if t < 0.15: alpha = (t / 0.15) * 0.52
		var col := Color(0.75, 0.3, 0.12, alpha * 1.2) if t < 0.35 else Color(0.24, 0.2, 0.23, alpha)
		draw_circle(p.pos, r, col)
		
	for e in volcano_embers:
		var t: float = float(e.life) / float(e.max_life)
		var col := Color(1.0, lerpf(0.9, 0.2, t), 0.05, (1.0 - t) * 0.95)
		draw_circle(e.pos, float(e.size) * (1.0 - t * 0.5), col)
		
	# ABRUPT RANDOM VOLCANO BURST!
	if burst_active:
		var b_alpha := (1.0 - burst_progress)
		# 1. Blinding white-hot caldera flash
		draw_circle(VOLCANO_CRATER, 70.0 * (1.0 + burst_progress * 0.5), Color(1.0, 0.95, 0.6, b_alpha * 0.85))
		# 2. Giant Magma Geyser erupting upward
		var geyser_height := 160.0 * sin(burst_progress * PI)
		draw_line(VOLCANO_CRATER, VOLCANO_CRATER + Vector2(-15, -geyser_height), Color(1.0, 0.45, 0.05, b_alpha), 16.0)
		draw_line(VOLCANO_CRATER, VOLCANO_CRATER + Vector2(-15, -geyser_height), Color(1.0, 0.95, 0.3, b_alpha), 8.0)
		# 3. Expanding fiery shockwave ring
		draw_arc(VOLCANO_CRATER, burst_shockwave_radius, 0, TAU, 36, Color(1.0, 0.6, 0.1, b_alpha * 0.7), 4.0)
		
	# Lava bombs arcing and exploding
	for bomb in lava_bombs:
		var t: float = float(bomb.life) / float(bomb.max_life)
		var a: float = (1.0 - t * 0.2)
		draw_circle(bomb.pos, float(bomb.size), Color(1.0, 0.75, 0.15, a))
		draw_circle(bomb.pos - bomb.vel * 0.08, float(bomb.size) * 0.65, Color(0.9, 0.25, 0.05, a * 0.8)) # Tail

# ------------------------------------------------------------------------------
# 6. DRAW ONYX SPIRE: OBSIDIAN MONSTER & GRIM REAPER (Matching Image)
# ------------------------------------------------------------------------------
func _draw_onyx_spire_and_reaper() -> void:
	# Gothic Fortress Wall & Arched Doorway
	var dp: Vector2 = CITADEL_DOOR_POS
	draw_rect(Rect2(dp + Vector2(-16, -35), Vector2(32, 50)), Color(0.08, 0.07, 0.1))
	
	# Door Opening animation
	var door_col := Color(0.2, 0.18, 0.25)
	if door_open_ratio > 0.0:
		# Interior mystical golden-white/dark void light spilling out
		draw_rect(Rect2(dp + Vector2(-14, -33), Vector2(28, 46)), Color(1.0, 0.85, 0.4, door_open_ratio * 0.65))
		# Swinging open doors
		var door_w := 14.0 * (1.0 - door_open_ratio)
		draw_rect(Rect2(dp + Vector2(-14, -33), Vector2(door_w, 46)), door_col)
		draw_rect(Rect2(dp + Vector2(14 - door_w, -33), Vector2(door_w, 46)), door_col)
	else:
		draw_rect(Rect2(dp + Vector2(-14, -33), Vector2(28, 46)), door_col)
		# Runic padlock glow when locked
		var lock_pulse := (sin(anim_time * 4.0) * 0.5 + 0.5)
		draw_circle(dp + Vector2(0, -10), 4.5, Color(0.8, 0.2, 0.95, 0.7 + lock_pulse * 0.3))
		
	# Obsidian Shadow Monster
	if reaper_cycle_timer < 12.0:
		var mp: Vector2 = obsidian_monster_pos
		# Jagged quadruped body with crystalline purple dorsal spikes
		draw_circle(mp, 7.5, Color(0.08, 0.06, 0.12))
		draw_circle(mp + Vector2(0, -5), 4.0, Color(0.65, 0.15, 0.9)) # Spikes
		draw_circle(mp + Vector2(4, -2), 1.8, Color(0.85, 0.2, 1.0)) # Glowing purple eyes
		draw_line(mp, mp + Vector2(-8, 8), Color(0.1, 0.08, 0.15), 2.2) # Limbs
		draw_line(mp, mp + Vector2(8, 8), Color(0.1, 0.08, 0.15), 2.2)
		
	# The Towering Grim Reaper (emerging when door is open, matching reference)
	if reaper_cycle_timer >= 7.0 and reaper_cycle_timer < 12.5:
		var rp := CITADEL_DOOR_POS + Vector2(-12, 12)
		
		# Crescent Moon / Divine Aura behind the Reaper (matching user's reference image!)
		draw_arc(rp + Vector2(0, -26), 24.0, -PI * 0.75, PI * 0.75, 24, Color(1.0, 0.9, 0.65, 0.75), 3.0)
		draw_circle(rp + Vector2(0, -26), 22.0, Color(1.0, 0.92, 0.7, 0.18))
		
		# Deep Cowled Black Hood & Robes (face is an abyss)
		var robe_poly := PackedVector2Array([
			rp + Vector2(-6, -34),
			rp + Vector2(6, -34),
			rp + Vector2(14, 15),
			rp + Vector2(-14, 15)
		])
		draw_colored_polygon(robe_poly, Color(0.06, 0.05, 0.08))
		# Void face inside cowl
		draw_circle(rp + Vector2(0, -26), 5.5, Color(0.0, 0.0, 0.0))
		
		# Flowing tattered black cape drifting in the wind
		draw_line(rp + Vector2(-10, -10), rp + Vector2(-24, 18), Color(0.08, 0.06, 0.1), 3.0)
		
		# Massive Ornate Crescent Scythe (matching reference image!)
		var scythe_staff_start := rp + Vector2(10, 16)
		var scythe_staff_end := rp + Vector2(10, -42)
		draw_line(scythe_staff_start, scythe_staff_end, Color(0.7, 0.65, 0.55), 2.5) # Staff
		# Crescent Scythe Blade curving menacingly
		var scythe_blade := PackedVector2Array([
			scythe_staff_end,
			scythe_staff_end + Vector2(-16, -8),
			scythe_staff_end + Vector2(-28, 4),
			scythe_staff_end + Vector2(-22, -2),
			scythe_staff_end + Vector2(-12, -12)
		])
		draw_colored_polygon(scythe_blade, Color(0.9, 0.92, 0.95))
		draw_polyline(scythe_blade, Color(1, 1, 1), 1.2)
		
		# Shadow tendrils dragging the obsidian monster (Phase 4)
		if reaper_cycle_timer >= 9.5 and reaper_cycle_timer < 12.0:
			draw_line(rp + Vector2(0, -10), obsidian_monster_pos, Color(0.5, 0.1, 0.8, 0.85), 2.5)
			draw_line(rp + Vector2(0, -10), obsidian_monster_pos + Vector2(-4, -4), Color(0.2, 0.05, 0.4, 0.9), 1.8)

# ------------------------------------------------------------------------------
# 7. DRAW SOARING FLYING DRAGON
# ------------------------------------------------------------------------------
func _draw_flying_dragon() -> void:
	if dragon_pos == Vector2.ZERO:
		return
		
	for p in dragon_trail_particles:
		var t: float = float(p.age) / float(p.lifetime)
		var a: float = (1.0 - t) * 0.85
		draw_circle(p.pos, 3.2 * (1.0 - t * 0.5), Color(p.col.r, p.col.g, p.col.b, a))
		
	var flap := sin(wing_phase)
	var wing_spread: float = 0.75 + flap * 0.35
	var wing_sweep: float = flap * 12.0
	
	# Ground Shadow
	var shadow_pos := dragon_pos + Vector2(28.0, 48.0)
	var shadow_col := Color(0.02, 0.02, 0.04, 0.32)
	_draw_dragon_silhouette(shadow_pos, dragon_heading, wing_spread, wing_sweep, shadow_col, 0.85)
	
	# Dragon Body & Wings
	var dragon_body_col := Color(0.18, 0.15, 0.22, 1.0)
	var wing_membrane_col := Color(0.72, 0.22, 0.15, 0.92)
	var wing_spar_col := Color(0.12, 0.1, 0.15, 1.0)
	var eye_col := Color(1.0, 0.85, 0.15, 1.0)
	
	_draw_dragon_figure(dragon_pos, dragon_heading, wing_spread, wing_sweep, dragon_body_col, wing_membrane_col, wing_spar_col, eye_col)

func _draw_dragon_silhouette(pos: Vector2, heading: float, spread: float, sweep: float, col: Color, scale_mult: float) -> void:
	var xform := Transform2D(heading, pos).scaled(Vector2(scale_mult, scale_mult))
	var left_wing := PackedVector2Array([
		xform * Vector2(4, -4),
		xform * Vector2(-16, -42 * spread + sweep),
		xform * Vector2(-36, -65 * spread + sweep),
		xform * Vector2(-28, -25 * spread),
		xform * Vector2(-8, 0)
	])
	var right_wing := PackedVector2Array([
		xform * Vector2(4, 4),
		xform * Vector2(-16, 42 * spread - sweep),
		xform * Vector2(-36, 65 * spread - sweep),
		xform * Vector2(-28, 25 * spread),
		xform * Vector2(-8, 0)
	])
	draw_colored_polygon(left_wing, col)
	draw_colored_polygon(right_wing, col)
	var body := PackedVector2Array([
		xform * Vector2(22, 0), xform * Vector2(8, -7), xform * Vector2(-22, -4),
		xform * Vector2(-54, 0), xform * Vector2(-22, 4), xform * Vector2(8, 7)
	])
	draw_colored_polygon(body, col)

func _draw_dragon_figure(pos: Vector2, heading: float, spread: float, sweep: float, body_col: Color, wing_col: Color, spar_col: Color, eye_col: Color) -> void:
	var xform := Transform2D(heading, pos)
	
	var left_wing_poly := PackedVector2Array([
		xform * Vector2(6, -6),
		xform * Vector2(-12, -46 * spread + sweep),
		xform * Vector2(-38, -72 * spread + sweep),
		xform * Vector2(-32, -38 * spread),
		xform * Vector2(-18, -18 * spread),
		xform * Vector2(-10, -3)
	])
	var right_wing_poly := PackedVector2Array([
		xform * Vector2(6, 6),
		xform * Vector2(-12, 46 * spread - sweep),
		xform * Vector2(-38, 72 * spread - sweep),
		xform * Vector2(-32, 38 * spread),
		xform * Vector2(-18, 18 * spread),
		xform * Vector2(-10, 3)
	])
	draw_colored_polygon(left_wing_poly, wing_col)
	draw_colored_polygon(right_wing_poly, wing_col)
	
	draw_line(xform * Vector2(6, -6), xform * Vector2(-12, -46 * spread + sweep), spar_col, 3.2)
	draw_line(xform * Vector2(-12, -46 * spread + sweep), xform * Vector2(-38, -72 * spread + sweep), spar_col, 2.5)
	draw_line(xform * Vector2(6, 6), xform * Vector2(-12, 46 * spread - sweep), spar_col, 3.2)
	draw_line(xform * Vector2(-12, 46 * spread - sweep), xform * Vector2(-38, 72 * spread - sweep), spar_col, 2.5)
	
	var body_poly := PackedVector2Array([
		xform * Vector2(25, 0), xform * Vector2(16, -6), xform * Vector2(4, -8),
		xform * Vector2(-20, -5), xform * Vector2(-42, -3), xform * Vector2(-65, 0),
		xform * Vector2(-42, 3), xform * Vector2(-20, 5), xform * Vector2(4, 8), xform * Vector2(16, 6)
	])
	draw_colored_polygon(body_poly, body_col)
	
	draw_circle(xform * Vector2(18, -3.5), 1.8, eye_col)
	draw_circle(xform * Vector2(18, 3.5), 1.8, eye_col)
