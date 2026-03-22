class_name EnemyBullet
extends Area2D

var _speed: float = 400.0
var _damage: int = 1
var _direction: Vector2 = Vector2.LEFT


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func initialize(pos: Vector2, dir: Vector2, speed: float, damage: int) -> void:
	global_position = pos
	_direction = dir.normalized()
	_speed = speed
	_damage = damage
	show()
	set_deferred("monitoring", true)


func deactivate() -> void:
	set_deferred("monitoring", false)
	hide()
	global_position = Vector2(-9999.0, -9999.0)


func _physics_process(delta: float) -> void:
	if not visible:
		return
	global_position += _direction * _speed * delta
	if global_position.x < -40.0 or global_position.x > 1960.0 \
			or global_position.y < -40.0 or global_position.y > 1120.0:
		BulletPoolManager.return_enemy_bullet(self)


func _on_body_entered(body: Node2D) -> void:
	if not visible:
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	BulletPoolManager.return_enemy_bullet(self)
