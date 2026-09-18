class_name ChapterLevelData
extends Resource

## Data-driven configuration resource for individual levels (1-10) within a chapter

@export var level_number: int = 1
@export var level_title: String = "Level 1"
@export var enemy_count: int = 8
@export var gem_count: int = 24

# Environmental / Atmospheric Settings
@export var sun_color: Color = Color(1.0, 0.96, 0.88)
@export var sun_energy: float = 1.35
@export var ambient_color: Color = Color(0.72, 0.85, 0.65)
@export var ambient_energy: float = 0.85
@export var fog_density: float = 0.002
@export var wind_particle_speed: float = 1.0

# Boss Level Flag
@export var is_boss_level: bool = false
@export var boss_name: String = ""
