class_name LevelChunk
extends Resource

## Define la lógica de spawns y transiciones de un bloque del nivel procedural
## y provee la escena física (chunk_scene) a instanciar en pantalla.

@export var chunk_type: StringName = "breathing" # "breathing", "pressure", "franchise", "elite", "transition", "boss"
@export var chunk_scene: PackedScene

@export var min_heat: int = 0
@export var max_heat: int = 4
@export var weight: float = 1.0
@export var duration_seconds: float = 15.0

## Array de diccionarios de spawn, ej: 
## [{"enemy_id": "zangano", "count": 3, "formation": "line", "delay": 2.0}]
@export var spawn_waves: Array[Dictionary] = []

## Transiciones de chunk_type permitidas (lista vacía = cualquiera que encaje por heat_level)
@export var next_chunk_types: Array[StringName] = []
