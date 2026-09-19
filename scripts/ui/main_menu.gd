extends Control

## LudusForge Premium Main Menu Controller
## Handles 360° hero rotation, idle & flip showcase animations, glowing platform FX,
## responsive fantasy UI, and complete interactive functionality for all landing page systems:
## - Spellbook (Level upgrades, stats preview, coin costs)
## - Daily Rewards (7-day calendar, coin & gem claim system)
## - Royal Missions (Progress bars, rewards claim, badge status)
## - Heroes Portal (Gacha summoning altar, single/10x summons, loot reveals)
## - Hero Roster (Pyromancer, Frost Weaver, Stormbringer, Void Sorcerer + platform lighting & flip)
## - Shop & Currency Vaults (Coin bundles, Gem packs, Starter pack)
## - Watch Ads (Simulated broadcast with progress timer, +400 coins reward)
## - Special Offers (Carousel ◀ ▶ navigation, bundle claims)
## - Community Join (+200 coins & +25 gems welcome reward)
## - Settings (Master/SFX/BGM volume sliders, quality selector, toggles)
## - Player Profile (Avatar, Level/XP bar, custom name editing & saving, career combat stats)
## - Equipment Vaults (Weapons, Armors, Rings with equip functionality & slot badges)
## - Modal Overlay with Kenney Fantasy UI borders & functional ✕ close button
## - Toast Notification system with celebratory animations

@export var rotation_sensitivity: float = 0.008
@export var flip_cooldown: float = 6.0

# 3D Node References
@onready var hero_platform: Node3D = $SubViewportContainer/SubViewport/ShowcaseWorld/HeroPlatform if has_node("SubViewportContainer/SubViewport/ShowcaseWorld/HeroPlatform") else null
@onready var hero_anchor: Node3D = $SubViewportContainer/SubViewport/ShowcaseWorld/HeroPlatform/HeroAnchor if has_node("SubViewportContainer/SubViewport/ShowcaseWorld/HeroPlatform/HeroAnchor") else null
@onready var rune_ring: MeshInstance3D = $SubViewportContainer/SubViewport/ShowcaseWorld/HeroPlatform/RuneRing if has_node("SubViewportContainer/SubViewport/ShowcaseWorld/HeroPlatform/RuneRing") else null
@onready var drag_hint: Control = $CenterOverlay/DragHint if has_node("CenterOverlay/DragHint") else null
@onready var play_button: Button = $BottomRightArea/PlayButton if has_node("BottomRightArea/PlayButton") else null

# 3D Lighting for Hero Classes
@onready var purple_rim_light: OmniLight3D = $SubViewportContainer/SubViewport/ShowcaseWorld/PurpleRimLight if has_node("SubViewportContainer/SubViewport/ShowcaseWorld/PurpleRimLight") else null
@onready var gold_front_light: OmniLight3D = $SubViewportContainer/SubViewport/ShowcaseWorld/GoldFrontLight if has_node("SubViewportContainer/SubViewport/ShowcaseWorld/GoldFrontLight") else null

# Top Bar References
@onready var player_name_label: Label = $TopLeftProfile/HBox/VBox/NameHBox/PlayerName if has_node("TopLeftProfile/HBox/VBox/NameHBox/PlayerName") else null
@onready var player_lvl_label: Label = $TopLeftProfile/HBox/VBox/NameHBox/LvlBadge if has_node("TopLeftProfile/HBox/VBox/NameHBox/LvlBadge") else null
@onready var player_xp_bar: ProgressBar = $TopLeftProfile/HBox/VBox/XPBar if has_node("TopLeftProfile/HBox/VBox/XPBar") else null
@onready var player_xp_text: Label = $TopLeftProfile/HBox/VBox/XPBar/XPText if has_node("TopLeftProfile/HBox/VBox/XPBar/XPText") else null
@onready var profile_card: PanelContainer = $TopLeftProfile if has_node("TopLeftProfile") else null

@onready var gold_amount_label: Label = $TopRightCurrencies/GoldCard/HBox/Amount if has_node("TopRightCurrencies/GoldCard/HBox/Amount") else null
@onready var add_gold_btn: Button = $TopRightCurrencies/GoldCard/HBox/AddBtn if has_node("TopRightCurrencies/GoldCard/HBox/AddBtn") else null
@onready var gems_amount_label: Label = $TopRightCurrencies/GemsCard/HBox/Amount if has_node("TopRightCurrencies/GemsCard/HBox/Amount") else null
@onready var add_gems_btn: Button = $TopRightCurrencies/GemsCard/HBox/AddBtn if has_node("TopRightCurrencies/GemsCard/HBox/AddBtn") else null
@onready var settings_btn: Button = $TopRightCurrencies/SettingsBtn if has_node("TopRightCurrencies/SettingsBtn") else null

# Left Navigation References
@onready var spellbook_btn: Button = $LeftNav/SpellbookBtn if has_node("LeftNav/SpellbookBtn") else null
@onready var rewards_btn: Button = $LeftNav/RewardsBtn if has_node("LeftNav/RewardsBtn") else null
@onready var missions_btn: Button = $LeftNav/MissionsBtn if has_node("LeftNav/MissionsBtn") else null
@onready var missions_badge: Panel = $LeftNav/MissionsBtn/Badge if has_node("LeftNav/MissionsBtn/Badge") else null
@onready var chapter_maps_btn: Button = $LeftNav/ChapterMapsBtn if has_node("LeftNav/ChapterMapsBtn") else null

# Lower Left Navigation References
@onready var heroes_portal_btn: Button = $LowerLeftNav/HeroesPortalBtn if has_node("LowerLeftNav/HeroesPortalBtn") else null
@onready var heroes_btn: Button = $LowerLeftNav/HeroesBtn if has_node("LowerLeftNav/HeroesBtn") else null
@onready var shop_btn: Button = $LowerLeftNav/ShopBtn if has_node("LowerLeftNav/ShopBtn") else null
@onready var shop_badge: Panel = $LowerLeftNav/ShopBtn/Badge if has_node("LowerLeftNav/ShopBtn/Badge") else null

# Right Promotions References
@onready var community_join_btn: Button = $RightPromotions/CommunityCard/HBox/JoinBtn if has_node("RightPromotions/CommunityCard/HBox/JoinBtn") else null
@onready var watch_ads_card: PanelContainer = $RightPromotions/WatchAdsCard if has_node("RightPromotions/WatchAdsCard") else null
@onready var special_offer_card: PanelContainer = $RightPromotions/SpecialOfferCard if has_node("RightPromotions/SpecialOfferCard") else null
@onready var special_left_btn: Button = $RightPromotions/SpecialOfferCard/VBox/HeaderHBox/LeftBtn if has_node("RightPromotions/SpecialOfferCard/VBox/HeaderHBox/LeftBtn") else null
@onready var special_right_btn: Button = $RightPromotions/SpecialOfferCard/VBox/HeaderHBox/RightBtn if has_node("RightPromotions/SpecialOfferCard/VBox/HeaderHBox/RightBtn") else null
@onready var special_title_label: Label = $RightPromotions/SpecialOfferCard/VBox/HeaderHBox/Title if has_node("RightPromotions/SpecialOfferCard/VBox/HeaderHBox/Title") else null
@onready var special_badge_label: Label = $RightPromotions/SpecialOfferCard/VBox/BodyHBox/CoinBadge if has_node("RightPromotions/SpecialOfferCard/VBox/BodyHBox/CoinBadge") else null
@onready var special_price_btn: Button = $RightPromotions/SpecialOfferCard/VBox/PriceBtn if has_node("RightPromotions/SpecialOfferCard/VBox/PriceBtn") else null

# Bottom Equipment Slots References
@onready var weapon_slot: PanelContainer = $BottomCenterEquipment/WeaponSlot if has_node("BottomCenterEquipment/WeaponSlot") else null
@onready var weapon_icon: Label = $BottomCenterEquipment/WeaponSlot/Icon if has_node("BottomCenterEquipment/WeaponSlot/Icon") else null
@onready var weapon_badge: Label = $BottomCenterEquipment/WeaponSlot/Badge if has_node("BottomCenterEquipment/WeaponSlot/Badge") else null

@onready var armor_slot: PanelContainer = $BottomCenterEquipment/ArmorSlot if has_node("BottomCenterEquipment/ArmorSlot") else null
@onready var armor_icon: Label = $BottomCenterEquipment/ArmorSlot/Icon if has_node("BottomCenterEquipment/ArmorSlot/Icon") else null
@onready var armor_badge: Label = $BottomCenterEquipment/ArmorSlot/Badge if has_node("BottomCenterEquipment/ArmorSlot/Badge") else null

@onready var ring_slot: PanelContainer = $BottomCenterEquipment/RingSlot if has_node("BottomCenterEquipment/RingSlot") else null
@onready var ring_icon: Label = $BottomCenterEquipment/RingSlot/Icon if has_node("BottomCenterEquipment/RingSlot/Icon") else null

# Modal Overlay & Toast
@onready var modal_overlay: Panel = $ModalOverlay if has_node("ModalOverlay") else null
@onready var modal_card: NinePatchRect = $ModalOverlay/ModalCard if has_node("ModalOverlay/ModalCard") else null
@onready var close_btn: Button = $ModalOverlay/ModalCard/CloseBtn if has_node("ModalOverlay/ModalCard/CloseBtn") else null
@onready var modal_title: Label = $ModalOverlay/ModalCard/ContentVBox/ModalTitle if has_node("ModalOverlay/ModalCard/ContentVBox/ModalTitle") else null
@onready var dynamic_content: VBoxContainer = $ModalOverlay/ModalCard/ContentVBox/BodyScroll/DynamicContent if has_node("ModalOverlay/ModalCard/ContentVBox/BodyScroll/DynamicContent") else null
@onready var action_btn: Button = $ModalOverlay/ModalCard/ContentVBox/ActionBtn if has_node("ModalOverlay/ModalCard/ContentVBox/ActionBtn") else null

@onready var toast_notification: NinePatchRect = $ToastNotification if has_node("ToastNotification") else null
@onready var toast_label: Label = $ToastNotification/ToastLabel if has_node("ToastNotification/ToastLabel") else null

# Interaction & Drag State
var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO
var target_hero_rotation: float = 0.0
var current_hero_rotation: float = 0.0
var has_rotated: bool = false

# Idle & Flip Animation State
var time_passed: float = 0.0
var is_flipping: bool = false
var flip_timer: float = 0.0
var player_instance: Node3D = null

# Game Data & Progression State
var player_name: String = "Player#5139"
var player_level: int = 2
var current_hero_id: String = "pyromancer"
var current_special_offer_idx: int = 0
var community_reward_claimed: bool = false

var spells_data: Dictionary = {
	"fireball": {"name": "Fireball", "icon": "🔥", "lvl": 3, "dmg": 85, "cd": 1.8, "cost": 300, "desc": "Launches a blazing explosive fireball dealing area burst damage."},
	"frost_nova": {"name": "Frost Nova", "icon": "❄️", "lvl": 2, "dmg": 50, "slow": 35, "cost": 400, "desc": "Emits a freezing frost burst that chills and slows enemy movements."},
	"thunderstrike": {"name": "Thunderstrike", "icon": "⚡", "lvl": 1, "dmg": 110, "stun": 0.8, "cost": 500, "desc": "Summons instantaneous divine lightning from the heavens."},
	"arcane_ward": {"name": "Arcane Ward", "icon": "🛡️", "lvl": 2, "shield": 150, "cost": 350, "desc": "Surrounds the caster with an absorbing magical forcefield."},
	"meteor_shower": {"name": "Meteor Shower", "icon": "☄️", "lvl": 1, "dmg": 220, "count": 6, "cost": 800, "desc": "Calls forth a devastating barrage of celestial flaming meteors."}
}

var daily_rewards: Array = [
	{"day": 1, "coins": 150, "gems": 0, "claimed": true},
	{"day": 2, "coins": 300, "gems": 0, "claimed": false},
	{"day": 3, "coins": 0, "gems": 15, "claimed": false},
	{"day": 4, "coins": 600, "gems": 0, "claimed": false},
	{"day": 5, "coins": 0, "gems": 35, "claimed": false},
	{"day": 6, "coins": 1200, "gems": 0, "claimed": false},
	{"day": 7, "coins": 2500, "gems": 100, "item": "👑 Mythic Crown", "claimed": false}
]

var missions_data: Array = [
	{"id": "gladiator", "title": "Arena Gladiator", "desc": "Defeat 5 enemies in battle", "curr": 5, "max": 5, "reward_coins": 350, "reward_gems": 0, "claimed": false},
	{"id": "caster", "title": "Spell Caster", "desc": "Cast 25 spells in matches", "curr": 18, "max": 25, "reward_coins": 200, "reward_gems": 0, "claimed": false},
	{"id": "explorer", "title": "World Explorer", "desc": "Reach Level 5 on the 100-Level Map", "curr": 5, "max": 5, "reward_coins": 0, "reward_gems": 25, "claimed": false},
	{"id": "master", "title": "Master of Elements", "desc": "Upgrade 2 spells in Spellbook", "curr": 2, "max": 2, "reward_coins": 500, "reward_gems": 0, "claimed": false}
]

const SPECIAL_OFFERS: Array = [
	{"title": "SPECIAL OFFER", "badge": "🪙 +50,000", "price": "₹150.00", "coins": 50000, "gems": 50},
	{"title": "ARCHMAGE ASCENSION", "badge": "💎 +1,000 & 🪙 +100k", "price": "₹299.00", "coins": 100000, "gems": 1000},
	{"title": "MYTHIC SOVEREIGN", "badge": "💎 +3,500 & 👑 Crown", "price": "₹499.00", "coins": 250000, "gems": 3500}
]

var equipped_items: Dictionary = {
	"weapon": "Apprentice Wand",
	"armor": "Novice Robe",
	"ring": "Ring of Vitality"
}

var settings_state: Dictionary = {
	"master_vol": 0.8,
	"sfx_vol": 0.9,
	"bgm_vol": 0.7,
	"quality": 0,
	"screen_shake": true,
	"haptics": true
}

const SAVE_DATA_PATH: String = "user://ludusforge_menu_data.json"
var toast_tween: Tween = null

func _ready() -> void:
	_load_menu_data()
	_setup_showcase_hero()
	_setup_button_effects()
	_connect_all_ui_buttons()
	_update_currency_display()
	_update_special_offer_display()
	_check_missions_badge()
	_animate_ui_entry()
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

func _setup_showcase_hero() -> void:
	if not hero_anchor:
		return
		
	for child in hero_anchor.get_children():
		child.queue_free()
		
	var player_scene: PackedScene = load("res://scenes/player/player.tscn") as PackedScene
	if player_scene:
		player_instance = player_scene.instantiate() as Node3D
		hero_anchor.add_child(player_instance)
		player_instance.position = Vector3.ZERO
		player_instance.rotation = Vector3.ZERO
		player_instance.scale = Vector3(0.55, 0.55, 0.55)
		player_instance.set_physics_process(false)
		player_instance.set_process_unhandled_input(false)
		
		var nameplate := player_instance.find_child("Nameplate3D", true, false)
		if nameplate:
			nameplate.visible = false
			
	_apply_hero_visuals(current_hero_id)

func _connect_all_ui_buttons() -> void:
	# Navigation & Feature Modals
	if spellbook_btn:
		spellbook_btn.pressed.connect(open_spellbook)
	if rewards_btn:
		rewards_btn.pressed.connect(open_rewards)
	if missions_btn:
		missions_btn.pressed.connect(open_missions)
	if chapter_maps_btn:
		chapter_maps_btn.pressed.connect(open_chapter_maps)
	if heroes_portal_btn:
		heroes_portal_btn.pressed.connect(open_heroes_portal)
	if heroes_btn:
		heroes_btn.pressed.connect(open_heroes)
	if shop_btn:
		shop_btn.pressed.connect(func(): open_shop("all"))
		
	# Top Right Currencies & Settings
	if add_gold_btn:
		add_gold_btn.pressed.connect(func(): open_shop("gold"))
	if add_gems_btn:
		add_gems_btn.pressed.connect(func(): open_shop("gems"))
	if settings_btn:
		settings_btn.pressed.connect(open_settings)
		
	# Top Left Profile Click
	if profile_card:
		profile_card.mouse_filter = Control.MOUSE_FILTER_STOP
		profile_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		profile_card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				open_profile()
		)
		
	# Right Promotions
	if community_join_btn:
		community_join_btn.pressed.connect(_on_community_join_pressed)
	if watch_ads_card:
		watch_ads_card.mouse_filter = Control.MOUSE_FILTER_STOP
		watch_ads_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		watch_ads_card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				open_watch_ads()
		)
	if special_left_btn:
		special_left_btn.pressed.connect(func(): _cycle_special_offer(-1))
	if special_right_btn:
		special_right_btn.pressed.connect(func(): _cycle_special_offer(1))
	if special_price_btn:
		special_price_btn.pressed.connect(_on_claim_special_offer)
		
	# Bottom Center Equipment Slots
	if weapon_slot:
		weapon_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		weapon_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		weapon_slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				open_equipment("weapon")
		)
	if armor_slot:
		armor_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		armor_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		armor_slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				open_equipment("armor")
		)
	if ring_slot:
		ring_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		ring_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ring_slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				open_equipment("ring")
		)
		
	# Modal Controls & Dismissal
	if close_btn:
		close_btn.pressed.connect(close_modal)
	if modal_overlay:
		modal_overlay.gui_input.connect(_on_modal_overlay_gui_input)

func _setup_button_effects() -> void:
	var buttons := find_children("*", "Button", true, false)
	for btn in buttons:
		var b := btn as Button
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.mouse_entered.connect(func():
			var tween := create_tween()
			tween.tween_property(b, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD)
		)
		b.mouse_exited.connect(func():
			var tween := create_tween()
			tween.tween_property(b, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD)
		)
		b.button_down.connect(func():
			var tween := create_tween()
			tween.tween_property(b, "scale", Vector2(0.96, 0.96), 0.05)
		)
		b.button_up.connect(func():
			var tween := create_tween()
			tween.tween_property(b, "scale", Vector2(1.04, 1.04), 0.08)
		)

func _animate_ui_entry() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ==============================================================================
# 3D HERO SHOWCASE, 360° DRAG ROTATION & FLIP ANIMATION
const CHAPTER_MAP_SCENES: Array[String] = [
	"res://scenes/maps/emerald_plains/emerald_plains.tscn",
	"res://scenes/maps/chapter_02_desert_mirage/desert_mirage.tscn",
	"res://scenes/maps/chapter_03_frostbite_tundra/frostbite_tundra.tscn",
	"res://scenes/maps/chapter_04_magma_core/magma_core.tscn",
	"res://scenes/maps/chapter_05_mystic_grove/mystic_grove.tscn",
	"res://scenes/maps/chapter_06_castle_ruins/castle_ruins.tscn",
	"res://scenes/maps/chapter_07_pirate_cove/pirate_cove.tscn",
	"res://scenes/maps/chapter_08_cursed_swamp/cursed_swamp.tscn",
	"res://scenes/maps/chapter_09_cosmic_void/cosmic_void.tscn",
	"res://scenes/maps/chapter_10_celestial_peak/celestial_peak.tscn",
]

func _unhandled_input(event: InputEvent) -> void:
	if modal_overlay and modal_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			close_modal()
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			trigger_hero_flip()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx: int = event.keycode - KEY_1
			if idx < CHAPTER_MAP_SCENES.size():
				get_tree().change_scene_to_file(CHAPTER_MAP_SCENES[idx])
		elif event.keycode == KEY_0:
			if CHAPTER_MAP_SCENES.size() > 9:
				get_tree().change_scene_to_file(CHAPTER_MAP_SCENES[9])
		elif event.keycode == KEY_M:
			open_chapter_maps()

func _gui_input(event: InputEvent) -> void:
	if modal_overlay and modal_overlay.visible:
		return
		
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				last_touch_pos = mb.position
			else:
				if is_dragging and (mb.position - last_touch_pos).length() < 6.0:
					trigger_hero_flip()
				is_dragging = false
				
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			is_dragging = true
			last_touch_pos = st.position
		else:
			if (st.position - last_touch_pos).length() < 12.0:
				trigger_hero_flip()
			is_dragging = false
			
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		_process_rotation_drag(mm.relative.x)
		
	elif event is InputEventScreenDrag and is_dragging:
		var sd := event as InputEventScreenDrag
		_process_rotation_drag(sd.relative.x)

func _process_rotation_drag(delta_x: float) -> void:
	target_hero_rotation += delta_x * rotation_sensitivity
	if not has_rotated and absf(delta_x) > 2.0:
		has_rotated = true
		if drag_hint:
			var tween := create_tween()
			tween.tween_property(drag_hint, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	time_passed += delta
	flip_timer += delta
	
	current_hero_rotation = lerp_angle(current_hero_rotation, target_hero_rotation, 12.0 * delta)
	if hero_anchor:
		hero_anchor.rotation.y = current_hero_rotation
		
	if rune_ring:
		rune_ring.rotation.y += delta * 0.4
		
	if hero_anchor and not is_flipping:
		var idle_breath := sin(time_passed * 2.5) * 0.02
		var idle_sway := cos(time_passed * 1.5) * 0.015
		hero_anchor.position.y = idle_breath
		hero_anchor.rotation.z = idle_sway
		
		if flip_timer >= flip_cooldown:
			trigger_hero_flip()

func trigger_hero_flip() -> void:
	if is_flipping or not hero_anchor:
		return
	is_flipping = true
	flip_timer = 0.0
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hero_anchor, "position:y", 0.65, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(hero_anchor, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(hero_anchor, "rotation:x", -TAU, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	if hero_anchor:
		hero_anchor.rotation.x = 0.0
		var squash_tween := create_tween()
		squash_tween.tween_property(hero_anchor, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
		squash_tween.tween_property(hero_anchor, "scale", Vector3.ONE, 0.12)
		
	is_flipping = false

func _apply_hero_visuals(hero_id: String) -> void:
	match hero_id:
		"pyromancer":
			if purple_rim_light: purple_rim_light.light_color = Color(0.95, 0.35, 0.15)
			if gold_front_light: gold_front_light.light_color = Color(1.0, 0.75, 0.2)
		"frost_weaver":
			if purple_rim_light: purple_rim_light.light_color = Color(0.2, 0.65, 0.95)
			if gold_front_light: gold_front_light.light_color = Color(0.5, 0.9, 1.0)
		"stormbringer":
			if purple_rim_light: purple_rim_light.light_color = Color(0.75, 0.25, 0.95)
			if gold_front_light: gold_front_light.light_color = Color(0.9, 0.85, 0.2)
		"void_sorcerer":
			if purple_rim_light: purple_rim_light.light_color = Color(0.4, 0.08, 0.6)
			if gold_front_light: gold_front_light.light_color = Color(0.65, 0.2, 0.85)

# ==============================================================================
# CURRENCY & STATE SYNC
# ==============================================================================

func _update_currency_display() -> void:
	var coins := 1126
	var gems := 0
	var xp := 120
	if LevelManager.instance:
		coins = LevelManager.instance.player_coins
		gems = LevelManager.instance.player_gems
		xp = LevelManager.instance.player_xp
		
	if gold_amount_label:
		gold_amount_label.text = str(coins)
	if gems_amount_label:
		gems_amount_label.text = str(gems)
		
	if player_name_label:
		player_name_label.text = player_name
	if player_lvl_label:
		player_lvl_label.text = "LVL %d" % player_level
	if player_xp_bar:
		player_xp_bar.max_value = 300
		player_xp_bar.value = xp
	if player_xp_text:
		player_xp_text.text = "%d / 300 XP" % xp

func _add_coins(amount: int) -> void:
	if LevelManager.instance:
		LevelManager.instance.player_coins += amount
		LevelManager.instance.save_progression()
	_update_currency_display()
	_animate_currency_bounce(gold_amount_label)

func _deduct_coins(amount: int) -> bool:
	var current := LevelManager.instance.player_coins if LevelManager.instance else 1126
	if current >= amount:
		if LevelManager.instance:
			LevelManager.instance.player_coins -= amount
			LevelManager.instance.save_progression()
		_update_currency_display()
		_animate_currency_bounce(gold_amount_label)
		return true
	return false

func _add_gems(amount: int) -> void:
	if LevelManager.instance:
		LevelManager.instance.player_gems += amount
		LevelManager.instance.save_progression()
	_update_currency_display()
	_animate_currency_bounce(gems_amount_label)

func _deduct_gems(amount: int) -> bool:
	var current := LevelManager.instance.player_gems if LevelManager.instance else 0
	if current >= amount:
		if LevelManager.instance:
			LevelManager.instance.player_gems -= amount
			LevelManager.instance.save_progression()
		_update_currency_display()
		_animate_currency_bounce(gems_amount_label)
		return true
	return false

func _animate_currency_bounce(label_node: Label) -> void:
	if not label_node:
		return
	var tween := create_tween()
	tween.tween_property(label_node, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(label_node, "scale", Vector2.ONE, 0.12)

func _check_missions_badge() -> void:
	if not missions_badge:
		return
	var has_unclaimed := false
	for m in missions_data:
		if int(m.curr) >= int(m.max) and not bool(m.claimed):
			has_unclaimed = true
			break
	missions_badge.visible = has_unclaimed

# ==============================================================================
# TOAST NOTIFICATION SYSTEM
# ==============================================================================

func show_toast(text: String, icon: String = "✨") -> void:
	if not toast_notification or not toast_label:
		return
		
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_label.text = "%s  %s" % [icon, text]
	toast_notification.visible = true
	toast_notification.modulate.a = 0.0
	toast_notification.scale = Vector2(0.85, 0.85)
	
	toast_tween = create_tween()
	toast_tween.set_parallel(true)
	toast_tween.tween_property(toast_notification, "modulate:a", 1.0, 0.18)
	toast_tween.tween_property(toast_notification, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	toast_tween.chain().tween_interval(1.8)
	toast_tween.chain().tween_property(toast_notification, "modulate:a", 0.0, 0.25)
	toast_tween.tween_callback(func(): toast_notification.visible = false)

# ==============================================================================
# MODAL OVERLAY LOGIC
# ==============================================================================

func open_modal(title_text: String) -> void:
	if not modal_overlay or not modal_card or not dynamic_content:
		return
		
	modal_title.text = title_text
	for c in dynamic_content.get_children():
		c.queue_free()
		
	modal_overlay.visible = true
	modal_overlay.modulate.a = 0.0
	modal_card.scale = Vector2(0.85, 0.85)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(modal_overlay, "modulate:a", 1.0, 0.18)
	tween.tween_property(modal_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_modal() -> void:
	if not modal_overlay or not modal_card:
		return
		
	var tween := create_tween().set_parallel(true)
	tween.tween_property(modal_overlay, "modulate:a", 0.0, 0.15)
	tween.tween_property(modal_card, "scale", Vector2(0.9, 0.9), 0.15)
	await tween.finished
	modal_overlay.visible = false
	_save_menu_data()

func _on_modal_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if modal_card and not modal_card.get_global_rect().has_point(mb.position):
			close_modal()

# Helper to create styled card panels for modal contents
func _create_card_panel(bg_col: Color = Color(0.12, 0.09, 0.18, 0.9), border_col: Color = Color(0.52, 0.32, 0.75, 0.9)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_border_width_all(2)
	sb.border_color = border_col
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_top = 10
	sb.content_margin_right = 12
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	return p

func _create_action_button(text: String, bg_color: Color = Color(0.92, 0.58, 0.08)) -> Button:
	var b := Button.new()
	b.text = text
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 0.85, 0.35)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", 14)
	return b

# ==============================================================================
# MODAL: SPELLBOOK
# ==============================================================================

func open_spellbook() -> void:
	open_modal("ARCANE SPELLBOOK")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var desc_lbl := Label.new()
	desc_lbl.text = "Upgrade your elemental spells using gold coins to amplify damage and lower cooldowns."
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic_content.add_child(desc_lbl)
	
	for spell_id in spells_data.keys():
		var spell: Dictionary = spells_data[spell_id]
		var card := _create_card_panel()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		# Spell Icon Box
		var icon_box := PanelContainer.new()
		icon_box.custom_minimum_size = Vector2(50, 50)
		var sb_icon := StyleBoxFlat.new()
		sb_icon.bg_color = Color(0.2, 0.12, 0.3)
		sb_icon.set_corner_radius_all(8)
		icon_box.add_theme_stylebox_override("panel", sb_icon)
		var icon_lbl := Label.new()
		icon_lbl.text = spell.icon
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_box.add_child(icon_lbl)
		hbox.add_child(icon_box)
		
		# Info VBox
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_hbox := HBoxContainer.new()
		var sname := Label.new()
		sname.text = str(spell.name)
		sname.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		sname.add_theme_font_size_override("font_size", 15)
		title_hbox.add_child(sname)
		
		var slvl := Label.new()
		slvl.text = " LVL %d" % int(spell.lvl)
		slvl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		slvl.add_theme_font_size_override("font_size", 13)
		title_hbox.add_child(slvl)
		info_vbox.add_child(title_hbox)
		
		var sdesc := Label.new()
		sdesc.text = str(spell.desc)
		sdesc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		sdesc.add_theme_font_size_override("font_size", 11)
		sdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(sdesc)
		
		var stats_lbl := Label.new()
		stats_lbl.text = "Power: %d DMG  •  Cooldown: %.1fs" % [int(spell.dmg), float(spell.get("cd", 2.0))]
		stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		stats_lbl.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(stats_lbl)
		hbox.add_child(info_vbox)
		
		# Upgrade Button
		var up_btn := _create_action_button("🪙 %d\nUPGRADE" % int(spell.cost))
		up_btn.custom_minimum_size = Vector2(90, 44)
		up_btn.pressed.connect(func():
			var cost: int = int(spell.cost)
			if _deduct_coins(cost):
				spell.lvl = int(spell.lvl) + 1
				spell.dmg = int(float(spell.dmg) * 1.25)
				spell.cost = int(float(spell.cost) * 1.5)
				show_toast("%s upgraded to LVL %d!" % [spell.name, spell.lvl], "🔥")
				open_spellbook()
			else:
				show_toast("Not enough Coins! Need 🪙 %d" % cost, "⚠️")
		)
		hbox.add_child(up_btn)
		dynamic_content.add_child(card)

# ==============================================================================
# MODAL: DAILY REWARDS
# ==============================================================================

func open_rewards() -> void:
	open_modal("7-DAY SANCTUARY REWARDS")
	action_btn.text = "CLAIM TODAY'S REWARD"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	
	var subtitle := Label.new()
	subtitle.text = "Return daily to claim precious Gold, Rare Gems, and Legendary Artifacts!"
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dynamic_content.add_child(subtitle)
	
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dynamic_content.add_child(grid)
	
	var can_claim_any := false
	var next_claimable_idx := -1
	
	for i in range(daily_rewards.size()):
		var rew: Dictionary = daily_rewards[i]
		var is_claimed: bool = bool(rew.claimed)
		var is_today: bool = (not is_claimed and next_claimable_idx == -1)
		if is_today:
			next_claimable_idx = i
			can_claim_any = true
			
		var card := _create_card_panel(
			Color(0.18, 0.14, 0.25, 0.95) if is_today else Color(0.1, 0.08, 0.14, 0.85),
			Color(0.95, 0.75, 0.2) if is_today else (Color(0.3, 0.7, 0.3) if is_claimed else Color(0.4, 0.3, 0.5))
		)
		card.custom_minimum_size = Vector2(130, 110)
		
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)
		
		var day_lbl := Label.new()
		day_lbl.text = "DAY %d" % int(rew.day)
		day_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if is_today else Color(0.8, 0.8, 0.9))
		day_lbl.add_theme_font_size_override("font_size", 13)
		day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(day_lbl)
		
		var icon_lbl := Label.new()
		icon_lbl.text = "👑" if rew.has("item") else ("💎" if int(rew.gems) > 0 else "🪙")
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(icon_lbl)
		
		var val_lbl := Label.new()
		if rew.has("item"):
			val_lbl.text = "+100 💎 + CROWN"
		elif int(rew.gems) > 0:
			val_lbl.text = "+%d GEMS" % int(rew.gems)
		else:
			val_lbl.text = "+%d COINS" % int(rew.coins)
		val_lbl.add_theme_font_size_override("font_size", 11)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(val_lbl)
		
		var status_lbl := Label.new()
		if is_claimed:
			status_lbl.text = "CLAIMED ✓"
			status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		elif is_today:
			status_lbl.text = "READY! 🎁"
			status_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		else:
			status_lbl.text = "LOCKED 🔒"
			status_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		status_lbl.add_theme_font_size_override("font_size", 10)
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(status_lbl)
		
		grid.add_child(card)
		
	if can_claim_any and next_claimable_idx != -1:
		action_btn.disabled = false
		action_btn.pressed.connect(func():
			var r: Dictionary = daily_rewards[next_claimable_idx]
			r.claimed = true
			if int(r.coins) > 0:
				_add_coins(int(r.coins))
			if int(r.gems) > 0:
				_add_gems(int(r.gems))
			show_toast("Day %d Reward Claimed!" % int(r.day), "🎁")
			open_rewards()
		, CONNECT_ONE_SHOT)
	else:
		action_btn.text = "ALL REWARDS CLAIMED ✓"
		action_btn.disabled = true

# ==============================================================================
# MODAL: ROYAL MISSIONS
# ==============================================================================

func open_missions() -> void:
	open_modal("ROYAL MISSIONS & QUESTS")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var sub := Label.new()
	sub.text = "Complete glorious trials across the realm to earn gold treasures and gems."
	sub.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	sub.add_theme_font_size_override("font_size", 13)
	dynamic_content.add_child(sub)
	
	for m in missions_data:
		var card := _create_card_panel()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		var icon_lbl := Label.new()
		icon_lbl.text = "📜"
		icon_lbl.add_theme_font_size_override("font_size", 26)
		hbox.add_child(icon_lbl)
		
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_lbl := Label.new()
		title_lbl.text = str(m.title)
		title_lbl.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
		title_lbl.add_theme_font_size_override("font_size", 14)
		info.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = str(m.desc)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(desc_lbl)
		
		# Progress Bar
		var pbar := ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 10)
		pbar.max_value = float(m.max)
		pbar.value = float(m.curr)
		pbar.show_percentage = false
		info.add_child(pbar)
		
		var prog_lbl := Label.new()
		prog_lbl.text = "Progress: %d / %d" % [int(m.curr), int(m.max)]
		prog_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
		prog_lbl.add_theme_font_size_override("font_size", 10)
		info.add_child(prog_lbl)
		hbox.add_child(info)
		
		# Claim Button
		var is_ready: bool = (int(m.curr) >= int(m.max))
		var is_claimed: bool = bool(m.claimed)
		var btn: Button = null
		if is_claimed:
			btn = _create_action_button("CLAIMED ✓", Color(0.2, 0.5, 0.2))
			btn.disabled = true
		elif is_ready:
			var rew_text := ("🪙 %d" % int(m.reward_coins)) if int(m.reward_coins) > 0 else ("💎 %d" % int(m.reward_gems))
			btn = _create_action_button("CLAIM\n" + rew_text, Color(0.92, 0.58, 0.08))
			btn.pressed.connect(func():
				m.claimed = true
				if int(m.reward_coins) > 0:
					_add_coins(int(m.reward_coins))
				if int(m.reward_gems) > 0:
					_add_gems(int(m.reward_gems))
				show_toast("Mission Complete! Reward claimed!", "🎉")
				_check_missions_badge()
				open_missions()
			)
		else:
			btn = _create_action_button("IN PROGRESS", Color(0.3, 0.25, 0.35))
			btn.disabled = true
		btn.custom_minimum_size = Vector2(100, 44)
		hbox.add_child(btn)
		
		dynamic_content.add_child(card)

# ==============================================================================
# MODAL: HEROES PORTAL (GACHA SUMMON)
# ==============================================================================

func open_heroes_portal() -> void:
	open_modal("MYSTIC HERO PORTAL")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var banner := Label.new()
	banner.text = "Channel ethereal runes to summon legendary hero shards, mythical tomes, and sacred relics!"
	banner.add_theme_color_override("font_color", Color(0.9, 0.82, 1.0))
	banner.add_theme_font_size_override("font_size", 13)
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic_content.add_child(banner)
	
	# Portal Altar Illustration
	var portal_box := _create_card_panel(Color(0.16, 0.08, 0.28, 0.95), Color(0.75, 0.35, 0.98))
	portal_box.custom_minimum_size = Vector2(0, 140)
	var pvbox := VBoxContainer.new()
	pvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pvbox.add_theme_constant_override("separation", 8)
	portal_box.add_child(pvbox)
	
	var altar_icon := Label.new()
	altar_icon.text = "🌀 ✨ 🔮"
	altar_icon.add_theme_font_size_override("font_size", 36)
	altar_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvbox.add_child(altar_icon)
	
	var rate_lbl := Label.new()
	rate_lbl.text = "★ ★ ★ ★ ★ LEGENDARY DROP RATE: 8.5%  •  EPIC RATE: 25.0%"
	rate_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	rate_lbl.add_theme_font_size_override("font_size", 11)
	rate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvbox.add_child(rate_lbl)
	dynamic_content.add_child(portal_box)
	
	# Summon Buttons Row
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	
	var free_btn := _create_action_button("🎁 FREE DAILY\nSUMMON", Color(0.2, 0.65, 0.45))
	free_btn.custom_minimum_size = Vector2(150, 52)
	free_btn.pressed.connect(func():
		_execute_summon("FREE DAILY SUMMON")
	)
	btn_hbox.add_child(free_btn)
	
	var single_btn := _create_action_button("💎 50 GEMS\nSUMMON x1", Color(0.55, 0.25, 0.85))
	single_btn.custom_minimum_size = Vector2(150, 52)
	single_btn.pressed.connect(func():
		if _deduct_gems(50):
			_execute_summon("SUMMON x1")
		else:
			show_toast("Need 50 Gems! Visit Shop to top up.", "💎")
	)
	btn_hbox.add_child(single_btn)
	
	var multi_btn := _create_action_button("💎 450 GEMS\nSUMMON x10", Color(0.92, 0.58, 0.08))
	multi_btn.custom_minimum_size = Vector2(150, 52)
	multi_btn.pressed.connect(func():
		if _deduct_gems(450):
			_execute_summon("SUMMON x10")
		else:
			show_toast("Need 450 Gems! Visit Shop to top up.", "💎")
	)
	btn_hbox.add_child(multi_btn)
	dynamic_content.add_child(btn_hbox)

func _execute_summon(type_name: String) -> void:
	var drops: Array = [
		{"name": "Stormbringer Hero Shard x10", "rarity": "★ ★ ★ ★ ★ LEGENDARY", "col": Color(1, 0.85, 0.2), "coins": 1000},
		{"name": "Frost Weaver Robe", "rarity": "★ ★ ★ ★ EPIC", "col": Color(0.7, 0.35, 1.0), "coins": 500},
		{"name": "Sunfire Wand Shard", "rarity": "★ ★ ★ RARE", "col": Color(0.3, 0.7, 1.0), "coins": 300},
		{"name": "Arcane Gem Pouch (+25 Gems)", "rarity": "★ ★ ★ RARE", "col": Color(0.2, 0.9, 0.7), "gems": 25}
	]
	var drop: Dictionary = drops.pick_random()
	if drop.has("coins"):
		_add_coins(int(drop.coins))
	if drop.has("gems"):
		_add_gems(int(drop.gems))
		
	trigger_hero_flip()
	show_toast("%s: %s [%s]!" % [type_name, drop.name, drop.rarity], "🌟")
	open_heroes_portal()

# ==============================================================================
# MODAL: HEROES ROSTER
# ==============================================================================

func open_heroes() -> void:
	open_modal("HERO SANCTUARY & ROSTER")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var heroes_list: Array = [
		{
			"id": "pyromancer",
			"name": "Ignis the Pyromancer",
			"class": "Flame Magus",
			"icon": "🧙‍♂️",
			"desc": "Master of incinerating fireballs and explosive blasts.",
			"stats": "ATK: 92  •  HP: 450  •  SPD: 5.2",
			"passive": "+15% Fire Spell Radius"
		},
		{
			"id": "frost_weaver",
			"name": "Lyra the Frost Weaver",
			"class": "Glacial Sorceress",
			"icon": "🧝‍♀️",
			"desc": "Commands blizzards and frost spells that cripple enemy movement.",
			"stats": "ATK: 78  •  HP: 520  •  SPD: 4.8",
			"passive": "Freezing attacks slow foes by 25%"
		},
		{
			"id": "stormbringer",
			"name": "Thorne the Stormbringer",
			"class": "Lightning Duelist",
			"icon": "⚡",
			"desc": "Channels heavens thunderbolts with furious attack speed.",
			"stats": "ATK: 88  •  HP: 480  •  SPD: 5.6",
			"passive": "+20% Attack and Cast Speed"
		},
		{
			"id": "void_sorcerer",
			"name": "Malakor the Void Sorcerer",
			"class": "Abyssal Warlock",
			"icon": "🔮",
			"desc": "Harvester of dark souls who drains life essence from enemies.",
			"stats": "ATK: 105  •  HP: 410  •  SPD: 5.0",
			"passive": "12% Life Steal on spell hits"
		}
	]
	
	for h in heroes_list:
		var is_equipped: bool = (current_hero_id == str(h.id))
		var card := _create_card_panel(
			Color(0.2, 0.15, 0.28, 0.95) if is_equipped else Color(0.12, 0.09, 0.16, 0.85),
			Color(0.95, 0.75, 0.2) if is_equipped else Color(0.4, 0.3, 0.6)
		)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		var icon_box := PanelContainer.new()
		icon_box.custom_minimum_size = Vector2(50, 50)
		var sb_i := StyleBoxFlat.new()
		sb_i.bg_color = Color(0.25, 0.15, 0.35)
		sb_i.set_corner_radius_all(8)
		icon_box.add_theme_stylebox_override("panel", sb_i)
		var il := Label.new()
		il.text = str(h.icon)
		il.add_theme_font_size_override("font_size", 26)
		il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		il.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_box.add_child(il)
		hbox.add_child(icon_box)
		
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_h := HBoxContainer.new()
		var n_lbl := Label.new()
		n_lbl.text = str(h.name)
		n_lbl.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
		n_lbl.add_theme_font_size_override("font_size", 14)
		title_h.add_child(n_lbl)
		
		var c_lbl := Label.new()
		c_lbl.text = " (" + str(h.class) + ")"
		c_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		c_lbl.add_theme_font_size_override("font_size", 12)
		title_h.add_child(c_lbl)
		info.add_child(title_h)
		
		var d_lbl := Label.new()
		d_lbl.text = str(h.desc)
		d_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		d_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(d_lbl)
		
		var s_lbl := Label.new()
		s_lbl.text = str(h.stats) + "  •  " + str(h.passive)
		s_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
		s_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(s_lbl)
		hbox.add_child(info)
		
		var btn: Button = null
		if is_equipped:
			btn = _create_action_button("EQUIPPED ✓", Color(0.2, 0.6, 0.3))
			btn.disabled = true
		else:
			btn = _create_action_button("EQUIP HERO", Color(0.92, 0.58, 0.08))
			btn.pressed.connect(func():
				current_hero_id = str(h.id)
				_apply_hero_visuals(current_hero_id)
				trigger_hero_flip()
				show_toast("%s Equipped!" % h.name, "🛡️")
				open_heroes()
			)
		btn.custom_minimum_size = Vector2(110, 44)
		hbox.add_child(btn)
		
		dynamic_content.add_child(card)

# ==============================================================================
# MODAL: FANTASY SHOP & TREASURY
# ==============================================================================

func open_shop(category: String = "all") -> void:
	open_modal("FANTASY TREASURY & SHOP")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	if category == "all" or category == "gold":
		var gh := Label.new()
		gh.text = "🪙 GOLD BUNDLES"
		gh.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		gh.add_theme_font_size_override("font_size", 14)
		dynamic_content.add_child(gh)
		
		var gold_items := [
			{"name": "Pouch of Gold", "coins": 2500, "gem_cost": 20},
			{"name": "Chest of Gold", "coins": 15000, "gem_cost": 100},
			{"name": "Mountain of Gold", "coins": 50000, "gem_cost": 300}
		]
		for item in gold_items:
			var card := _create_card_panel()
			var hb := HBoxContainer.new()
			card.add_child(hb)
			
			var il := Label.new()
			il.text = "🪙"
			il.add_theme_font_size_override("font_size", 24)
			hb.add_child(il)
			
			var vb := VBoxContainer.new()
			vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var n := Label.new()
			n.text = item.name + " (+%d Coins)" % item.coins
			n.add_theme_font_size_override("font_size", 13)
			vb.add_child(n)
			hb.add_child(vb)
			
			var btn := _create_action_button("💎 %d BUY" % item.gem_cost)
			btn.pressed.connect(func():
				if _deduct_gems(item.gem_cost):
					_add_coins(item.coins)
					show_toast("+%d Coins Added to Vault!" % item.coins, "🪙")
				else:
					show_toast("Need %d Gems!" % item.gem_cost, "💎")
			)
			hb.add_child(btn)
			dynamic_content.add_child(card)
			
	if category == "all" or category == "gems":
		var gem_h := Label.new()
		gem_h.text = "💎 GEM VAULTS"
		gem_h.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		gem_h.add_theme_font_size_override("font_size", 14)
		dynamic_content.add_child(gem_h)
		
		var gem_packs := [
			{"name": "Pouch of Gems", "gems": 100, "price": "$0.99 (Free Demo)"},
			{"name": "Chest of Gems", "gems": 500, "price": "$4.99 (Free Demo)"},
			{"name": "Vault of Gems", "gems": 2000, "price": "$14.99 (Free Demo)"}
		]
		for pack in gem_packs:
			var card := _create_card_panel()
			var hb := HBoxContainer.new()
			card.add_child(hb)
			
			var il := Label.new()
			il.text = "💎"
			il.add_theme_font_size_override("font_size", 24)
			hb.add_child(il)
			
			var vb := VBoxContainer.new()
			vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var n := Label.new()
			n.text = pack.name + " (+%d Gems)" % pack.gems
			n.add_theme_font_size_override("font_size", 13)
			vb.add_child(n)
			hb.add_child(vb)
			
			var btn := _create_action_button("CLAIM %s" % pack.price, Color(0.2, 0.6, 0.9))
			btn.pressed.connect(func():
				_add_gems(pack.gems)
				show_toast("+%d Gems Acquired!" % pack.gems, "💎")
			)
			hb.add_child(btn)
			dynamic_content.add_child(card)

# ==============================================================================
# MODAL: WATCH ADS (SIMULATION WITH TIMER & REWARD)
# ==============================================================================

func open_watch_ads() -> void:
	open_modal("SPONSOR BROADCAST")
	action_btn.visible = false
	
	var desc := Label.new()
	desc.text = "Streaming official LudusForge magical sponsor clip...\nPlease wait 2 seconds to claim your free reward."
	desc.add_theme_font_size_override("font_size", 13)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dynamic_content.add_child(desc)
	
	var ad_panel := _create_card_panel(Color(0.08, 0.25, 0.45, 0.95), Color(0.25, 0.68, 0.98))
	ad_panel.custom_minimum_size = Vector2(0, 140)
	var ad_vbox := VBoxContainer.new()
	ad_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ad_panel.add_child(ad_vbox)
	
	var ad_icon := Label.new()
	ad_icon.text = "📺 🎮 🪄"
	ad_icon.add_theme_font_size_override("font_size", 38)
	ad_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_vbox.add_child(ad_icon)
	
	var ad_status := Label.new()
	ad_status.text = "Watching sponsor reel: 0%"
	ad_status.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
	ad_status.add_theme_font_size_override("font_size", 13)
	ad_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_vbox.add_child(ad_status)
	
	var pbar := ProgressBar.new()
	pbar.custom_minimum_size = Vector2(300, 16)
	pbar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pbar.max_value = 100.0
	pbar.value = 0.0
	ad_vbox.add_child(pbar)
	dynamic_content.add_child(ad_panel)
	
	var tween := create_tween()
	tween.tween_property(pbar, "value", 100.0, 2.0)
	tween.parallel().tween_method(func(val: float):
		ad_status.text = "Watching sponsor reel: %d%%" % int(val)
	, 0.0, 100.0, 2.0)
	
	await tween.finished
	_add_coins(400)
	show_toast("+400 Coins Earned from Ad!", "🪙")
	action_btn.visible = true
	action_btn.text = "COLLECT & CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)

# ==============================================================================
# SPECIAL OFFERS & COMMUNITY
# ==============================================================================

func _update_special_offer_display() -> void:
	var offer: Dictionary = SPECIAL_OFFERS[current_special_offer_idx]
	if special_title_label:
		special_title_label.text = str(offer.title)
	if special_badge_label:
		special_badge_label.text = str(offer.badge)
	if special_price_btn:
		special_price_btn.text = str(offer.price)

func _cycle_special_offer(delta_idx: int) -> void:
	current_special_offer_idx = (current_special_offer_idx + delta_idx + SPECIAL_OFFERS.size()) % SPECIAL_OFFERS.size()
	_update_special_offer_display()

func _on_claim_special_offer() -> void:
	var offer: Dictionary = SPECIAL_OFFERS[current_special_offer_idx]
	_add_coins(int(offer.coins))
	_add_gems(int(offer.gems))
	show_toast("%s Claimed! +%d Coins +%d Gems!" % [offer.title, int(offer.coins), int(offer.gems)], "🎉")

func _on_community_join_pressed() -> void:
	if not community_reward_claimed:
		community_reward_claimed = true
		_add_coins(200)
		_add_gems(25)
		show_toast("Joined Community! Welcome Gift: +200 🪙 +25 💎!", "💬")
	else:
		show_toast("Welcome back! Community perks active.", "💬")

# ==============================================================================
# MODAL: SETTINGS
# ==============================================================================

func open_settings() -> void:
	open_modal("GAME SETTINGS")
	action_btn.text = "SAVE & CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	# Master Volume Slider
	var mv_box := _create_card_panel()
	var mv_vbox := VBoxContainer.new()
	mv_box.add_child(mv_vbox)
	var mv_lbl := Label.new()
	mv_lbl.text = "🔊 Master Volume: %d%%" % int(float(settings_state.master_vol) * 100)
	mv_vbox.add_child(mv_lbl)
	var mv_slider := HSlider.new()
	mv_slider.min_value = 0.0
	mv_slider.max_value = 1.0
	mv_slider.step = 0.05
	mv_slider.value = float(settings_state.master_vol)
	mv_slider.value_changed.connect(func(v: float):
		settings_state.master_vol = v
		mv_lbl.text = "🔊 Master Volume: %d%%" % int(v * 100)
	)
	mv_vbox.add_child(mv_slider)
	dynamic_content.add_child(mv_box)
	
	# SFX Volume Slider
	var sfx_box := _create_card_panel()
	var sfx_vbox := VBoxContainer.new()
	sfx_box.add_child(sfx_vbox)
	var sfx_lbl := Label.new()
	sfx_lbl.text = "⚔️ SFX Combat Audio: %d%%" % int(float(settings_state.sfx_vol) * 100)
	sfx_vbox.add_child(sfx_lbl)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = float(settings_state.sfx_vol)
	sfx_slider.value_changed.connect(func(v: float):
		settings_state.sfx_vol = v
		sfx_lbl.text = "⚔️ SFX Combat Audio: %d%%" % int(v * 100)
	)
	sfx_vbox.add_child(sfx_slider)
	dynamic_content.add_child(sfx_box)
	
	# Quality Selector & Screen Shake
	var opt_box := _create_card_panel()
	var opt_vbox := VBoxContainer.new()
	opt_box.add_child(opt_vbox)
	
	var shake_check := CheckButton.new()
	shake_check.text = "💥 Screen Shake & Impact Feedback"
	shake_check.button_pressed = bool(settings_state.screen_shake)
	shake_check.toggled.connect(func(b: bool): settings_state.screen_shake = b)
	opt_vbox.add_child(shake_check)
	
	var haptics_check := CheckButton.new()
	haptics_check.text = "📳 Haptic Vibrations"
	haptics_check.button_pressed = bool(settings_state.haptics)
	haptics_check.toggled.connect(func(b: bool): settings_state.haptics = b)
	opt_vbox.add_child(haptics_check)
	dynamic_content.add_child(opt_box)

# ==============================================================================
# MODAL: PLAYER PROFILE
# ==============================================================================

func open_profile() -> void:
	open_modal("CHAMPION PROFILE")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var head_panel := _create_card_panel(Color(0.18, 0.12, 0.28, 0.95), Color(0.95, 0.75, 0.25))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	head_panel.add_child(hb)
	
	var av := Label.new()
	av.text = "🧙‍♂️"
	av.add_theme_font_size_override("font_size", 42)
	hb.add_child(av)
	
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Editable Name Row
	var name_edit_hb := HBoxContainer.new()
	var name_input := LineEdit.new()
	name_input.text = player_name
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit_hb.add_child(name_input)
	
	var save_name_btn := _create_action_button("RENAME")
	save_name_btn.pressed.connect(func():
		var new_n := name_input.text.strip_edges()
		if new_n != "":
			player_name = new_n
			_update_currency_display()
			show_toast("Name updated to %s!" % player_name, "✏️")
	)
	name_edit_hb.add_child(save_name_btn)
	vb.add_child(name_edit_hb)
	
	var rank_lbl := Label.new()
	rank_lbl.text = "Rank: Arcane Apprentice (Level %d)" % player_level
	rank_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	rank_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(rank_lbl)
	hb.add_child(vb)
	dynamic_content.add_child(head_panel)
	
	# Career Stats Box
	var stats_box := _create_card_panel()
	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 6)
	stats_box.add_child(svb)
	
	var sh := Label.new()
	sh.text = "🏆 COMBAT STATISTICS"
	sh.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	sh.add_theme_font_size_override("font_size", 13)
	svb.add_child(sh)
	
	var s1 := Label.new()
	s1.text = "• Matches Won: 12 / 15 (80.0% Victory Rate)"
	svb.add_child(s1)
	
	var s2 := Label.new()
	s2.text = "• Enemies Eliminated: 64 Foes"
	svb.add_child(s2)
	
	var s3 := Label.new()
	s3.text = "• Progression Map: Region 1 (Stage 1 / 100)"
	svb.add_child(s3)
	
	var s4 := Label.new()
	s4.text = "• Primary Specialty: Pyromancy & Fireball"
	svb.add_child(s4)
	dynamic_content.add_child(stats_box)

# ==============================================================================
# MODAL: EQUIPMENT (WEAPON, ARMOR, RING)
# ==============================================================================

func open_equipment(slot_type: String) -> void:
	var title := "EQUIPMENT ARSENAL"
	match slot_type:
		"weapon": title = "WEAPONS ARSENAL"
		"armor": title = "ROBES & ARMOR"
		"ring": title = "ENCHANTED RINGS"
		
	open_modal(title)
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var items: Array = []
	match slot_type:
		"weapon":
			items = [
				{"name": "Apprentice Wand", "icon": "⚔️", "bonus": "+15 Magic Power", "lvl": 1},
				{"name": "Sunfire Staff", "icon": "🪄", "bonus": "+35 Fire Power & Burn", "lvl": 2},
				{"name": "Void Blade", "icon": "🗡️", "bonus": "+55 Dark Power & Siphon", "lvl": 3}
			]
		"armor":
			items = [
				{"name": "Novice Robe", "icon": "🛡️", "bonus": "+10 Armor, +50 HP", "lvl": 1},
				{"name": "Battlemage Cuirass", "icon": "🥋", "bonus": "+25 Armor, +120 HP", "lvl": 2},
				{"name": "Celestial Mantle", "icon": "🧥", "bonus": "+45 Armor, Spell Shield", "lvl": 3}
			]
		"ring":
			items = [
				{"name": "Ring of Vitality", "icon": "💍", "bonus": "+30 Max Health", "lvl": 1},
				{"name": "Band of Haste", "icon": "💍", "bonus": "+15% Move Speed", "lvl": 2},
				{"name": "Ring of Destruction", "icon": "💍", "bonus": "+20% Spell Critical", "lvl": 3}
			]
			
	for itm in items:
		var is_equipped: bool = (equipped_items.get(slot_type, "") == str(itm.name))
		var card := _create_card_panel(
			Color(0.2, 0.15, 0.28, 0.95) if is_equipped else Color(0.12, 0.09, 0.16, 0.85),
			Color(0.95, 0.75, 0.2) if is_equipped else Color(0.4, 0.3, 0.6)
		)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		card.add_child(hb)
		
		var icon_lbl := Label.new()
		icon_lbl.text = str(itm.icon)
		icon_lbl.add_theme_font_size_override("font_size", 26)
		hb.add_child(icon_lbl)
		
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n_lbl := Label.new()
		n_lbl.text = str(itm.name) + " (Tier %d)" % int(itm.lvl)
		n_lbl.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
		n_lbl.add_theme_font_size_override("font_size", 14)
		vb.add_child(n_lbl)
		
		var b_lbl := Label.new()
		b_lbl.text = str(itm.bonus)
		b_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		b_lbl.add_theme_font_size_override("font_size", 11)
		vb.add_child(b_lbl)
		hb.add_child(vb)
		
		var btn: Button = null
		if is_equipped:
			btn = _create_action_button("EQUIPPED ✓", Color(0.2, 0.6, 0.3))
			btn.disabled = true
		else:
			btn = _create_action_button("EQUIP", Color(0.92, 0.58, 0.08))
			btn.pressed.connect(func():
				equipped_items[slot_type] = str(itm.name)
				match slot_type:
					"weapon":
						if weapon_icon: weapon_icon.text = str(itm.icon)
						if weapon_badge: weapon_badge.text = str(itm.lvl)
					"armor":
						if armor_icon: armor_icon.text = str(itm.icon)
						if armor_badge: armor_badge.text = str(itm.lvl)
					"ring":
						if ring_icon: ring_icon.text = str(itm.icon)
				show_toast("%s Equipped!" % itm.name, "⚔️")
				open_equipment(slot_type)
			)
		btn.custom_minimum_size = Vector2(100, 42)
		hb.add_child(btn)
		dynamic_content.add_child(card)

# ==============================================================================
# SAVE & LOAD STATE PERSISTENCE
# ==============================================================================

func _save_menu_data() -> void:
	var data := {
		"player_name": player_name,
		"player_level": player_level,
		"current_hero_id": current_hero_id,
		"spells_data": spells_data,
		"daily_rewards": daily_rewards,
		"missions_data": missions_data,
		"equipped_items": equipped_items,
		"settings_state": settings_state,
		"community_reward_claimed": community_reward_claimed
	}
	var f := FileAccess.open(SAVE_DATA_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func _load_menu_data() -> void:
	if not FileAccess.file_exists(SAVE_DATA_PATH):
		return
	var f := FileAccess.open(SAVE_DATA_PATH, FileAccess.READ)
	if f:
		var text := f.get_as_text()
		f.close()
		var json := JSON.new()
		if json.parse(text) == OK and json.data is Dictionary:
			var d: Dictionary = json.data
			player_name = str(d.get("player_name", player_name))
			player_level = int(d.get("player_level", player_level))
			current_hero_id = str(d.get("current_hero_id", current_hero_id))
			community_reward_claimed = bool(d.get("community_reward_claimed", community_reward_claimed))
			if d.has("spells_data") and d.spells_data is Dictionary:
				spells_data = d.spells_data
			if d.has("daily_rewards") and d.daily_rewards is Array:
				daily_rewards = d.daily_rewards
			if d.has("missions_data") and d.missions_data is Array:
				missions_data = d.missions_data
			if d.has("equipped_items") and d.equipped_items is Dictionary:
				equipped_items = d.equipped_items
			if d.has("settings_state") and d.settings_state is Dictionary:
				settings_state = d.settings_state

# ==============================================================================
# MODAL: GANESH'S 10 CHAPTER MAPS & BOSSES
# ==============================================================================

func open_chapter_maps() -> void:
	open_modal("10 CHAPTER MAPS & BOSSES")
	action_btn.text = "CLOSE"
	action_btn.pressed.disconnect(close_modal) if action_btn.pressed.is_connected(close_modal) else null
	action_btn.pressed.connect(close_modal, CONNECT_ONE_SHOT)
	
	var sub := Label.new()
	sub.text = "Select any of Ganesh's 3D Chapter Maps to immediately battle the chapter's boss with Heavenly Ascendant:"
	sub.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	sub.add_theme_font_size_override("font_size", 13)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic_content.add_child(sub)
	
	var chapter_data: Array = [
		{"name": "Chapter 1: Emerald Plains", "boss": "👑 Gorgon Treant King", "scene": "res://scenes/maps/emerald_plains/emerald_plains.tscn", "icon": "🌲"},
		{"name": "Chapter 2: Desert Mirage", "boss": "💀 Anubis Scythe Lord", "scene": "res://scenes/maps/chapter_02_desert_mirage/desert_mirage.tscn", "icon": "🏜️"},
		{"name": "Chapter 3: Frostbite Tundra", "boss": "❄️ Frost Fiend Ymir", "scene": "res://scenes/maps/chapter_03_frostbite_tundra/frostbite_tundra.tscn", "icon": "⛄"},
		{"name": "Chapter 4: Magma Core", "boss": "🌋 Ignis Molten Overlord", "scene": "res://scenes/maps/chapter_04_magma_core/magma_core.tscn", "icon": "🔥"},
		{"name": "Chapter 5: Mystic Grove", "boss": "🍄 Spore Queen Nightshade", "scene": "res://scenes/maps/chapter_05_mystic_grove/mystic_grove.tscn", "icon": "🌿"},
		{"name": "Chapter 6: Castle Ruins", "boss": "⚔️ Warlord Iron Bane", "scene": "res://scenes/maps/chapter_06_castle_ruins/castle_ruins.tscn", "icon": "🏰"},
		{"name": "Chapter 7: Pirate Cove", "boss": "🏴‍☠️ Captain Davy Blood Tide", "scene": "res://scenes/maps/chapter_07_pirate_cove/pirate_cove.tscn", "icon": "⚓"},
		{"name": "Chapter 8: Cursed Swamp", "boss": "🧟 Lord Malakor", "scene": "res://scenes/maps/chapter_08_cursed_swamp/cursed_swamp.tscn", "icon": "🦇"},
		{"name": "Chapter 9: Cosmic Void", "boss": "🌌 Xeno Gorgon Apex", "scene": "res://scenes/maps/chapter_09_cosmic_void/cosmic_void.tscn", "icon": "🪐"},
		{"name": "Chapter 10: Celestial Peak", "boss": "✨ Judgment Seraph", "scene": "res://scenes/maps/chapter_10_celestial_peak/celestial_peak.tscn", "icon": "☀️"},
	]
	
	for c in chapter_data:
		var card := _create_card_panel()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		var icon_lbl := Label.new()
		icon_lbl.text = c.icon
		icon_lbl.add_theme_font_size_override("font_size", 24)
		hbox.add_child(icon_lbl)
		
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = c.name
		title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		title.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(title)
		
		var boss_lbl := Label.new()
		boss_lbl.text = "Boss: %s" % c.boss
		boss_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		boss_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(boss_lbl)
		hbox.add_child(info_vbox)
		
		var battle_btn := _create_action_button("BATTLE ▶", Color(0.2, 0.65, 0.35))
		var scene_path: String = c.scene
		battle_btn.pressed.connect(func():
			get_tree().change_scene_to_file(scene_path)
		)
		hbox.add_child(battle_btn)
		dynamic_content.add_child(card)

# ==============================================================================
# PLAY TRANSITION
# ==============================================================================

func _on_play_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		var level_select_scene := "res://scenes/ui/level_select.tscn"
		if ResourceLoader.exists(level_select_scene):
			get_tree().change_scene_to_file(level_select_scene)
		else:
			get_tree().change_scene_to_file("res://scenes/ui/matchmaking_screen.tscn")
	)
