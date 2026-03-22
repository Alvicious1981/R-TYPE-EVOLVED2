extends Node

const POOL_SIZE: int = 2000
const _BULLET_SCENE: PackedScene = preload("res://scenes/entities/Bullet.tscn")

const ENEMY_POOL_SIZE: int = 500
const _ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/entities/EnemyBullet.tscn")

var _available: Array[Bullet] = []
var _active: Array[Bullet] = []

var _enemy_available: Array[EnemyBullet] = []
var _enemy_active: Array[EnemyBullet] = []


func _ready() -> void:
	for i: int in POOL_SIZE:
		var bullet: Bullet = _BULLET_SCENE.instantiate() as Bullet
		add_child(bullet)
		bullet.deactivate()
		_available.append(bullet)
	for i: int in ENEMY_POOL_SIZE:
		var bullet: EnemyBullet = _ENEMY_BULLET_SCENE.instantiate() as EnemyBullet
		add_child(bullet)
		bullet.deactivate()
		_enemy_available.append(bullet)


func get_bullet(pos: Vector2, dir: Vector2, speed: float = 600.0, damage: int = 1) -> Bullet:
	if _available.is_empty():
		push_warning("BulletPool exhausted — consider increasing POOL_SIZE")
		return null
	var bullet: Bullet = _available.pop_back()
	bullet.initialize(pos, dir, speed, damage)
	_active.append(bullet)
	return bullet


func return_bullet(bullet: Bullet) -> void:
	if bullet == null:
		return
	bullet.deactivate()
	_active.erase(bullet)
	_available.append(bullet)


func get_enemy_bullet(pos: Vector2, dir: Vector2, speed: float = 400.0, damage: int = 1) -> EnemyBullet:
	if _enemy_available.is_empty():
		push_warning("EnemyBulletPool exhausted — consider increasing ENEMY_POOL_SIZE")
		return null
	var bullet: EnemyBullet = _enemy_available.pop_back()
	bullet.initialize(pos, dir, speed, damage)
	_enemy_active.append(bullet)
	return bullet


func return_enemy_bullet(bullet: EnemyBullet) -> void:
	if bullet == null:
		return
	bullet.deactivate()
	_enemy_active.erase(bullet)
	_enemy_available.append(bullet)
