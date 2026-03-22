class_name CameraShake extends Camera2D

const MAX_OFFSET := Vector2(16.0, 12.0)
const DECAY_RATE: float = 2.0

var _trauma: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.boss_defeated.connect(_on_boss_defeated)


func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - DECAY_RATE * delta, 0.0)
	var shake: float = _trauma * _trauma
	offset.x = MAX_OFFSET.x * shake * _rng.randf_range(-1.0, 1.0)
	offset.y = MAX_OFFSET.y * shake * _rng.randf_range(-1.0, 1.0)


func _on_enemy_destroyed(_score: int, _pos: Vector2) -> void:
	add_trauma(0.1)


func _on_boss_defeated() -> void:
	add_trauma(0.4)
