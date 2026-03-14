class_name LevelChunk
extends Resource

## Dicta qué bloques pre-esculpidos están autorizados según
## el Nivel de Calor activo. (TDD §1.1)

@export var chunk_scene: PackedScene
@export var heat_level_req: int = 0
@export var spawn_weight: float = 1.0
