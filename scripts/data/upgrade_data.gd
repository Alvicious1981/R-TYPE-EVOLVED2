class_name UpgradeData
extends Resource

## Base de datos atómica de la Tienda. Separa datos mercantiles
## de la lógica del personaje. (TDD §1.1)
## M20: Ampliado con campos de power-ups temporales in-run.

@export var id: String = ""
@export var cost_scrap: int = 0
@export var icon: Texture2D
@export var stat_modifier_dict: Dictionary = {}

## M20 — Power-Up In-Run fields
@export var is_temporary: bool = false
## Identificador del efecto: pu_rapid_fire, pu_speed_boost, pu_shield_pulse,
## pu_scrap_magnet, pu_wave_amp
@export var effect_type: StringName = &""
## Duración en segundos. -1.0 = toda la run (no expira)
@export var duration: float = -1.0
## Multiplicador del efecto (semántica depende de effect_type)
@export var magnitude: float = 1.0
