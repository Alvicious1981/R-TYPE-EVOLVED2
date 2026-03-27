class_name EnemyProfile
extends Resource

## Modela la diversidad enemiga. Una única Enemy.tscn inyecta este recurso
## en _ready() para adoptar estadísticas e IA. (TDD §1.1)

@export var id: String = ""
@export var max_hp: int = 0
@export var point_value: int = 0
@export var texture_path: String = ""
@export var display_scale: Vector2 = Vector2(0.038, 0.038)
@export var projectile_pattern: Array[Dictionary] = []
