extends Node

signal score_changed(new_score: int)

var current_score: int = 0


func _ready() -> void:
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed(score_value: int, _position: Vector2) -> void:
	add_score(score_value)


func add_score(value: int) -> void:
	current_score += value
	score_changed.emit(current_score)


func reset() -> void:
	current_score = 0
	score_changed.emit(0)
