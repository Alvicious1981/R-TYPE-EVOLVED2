extends Node

const POOL_SIZE: int = 2000
const _BULLET_SCENE: PackedScene = preload("res://scenes/entities/Bullet.tscn")

const ENEMY_POOL_SIZE: int = 500
const _ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/entities/EnemyBullet.tscn")

const WAVE_POOL_SIZE: int = 10
## load() en _ready() para evitar dependencia circular de preload con WaveBullet
var _wave_bullet_scene: PackedScene

var _available: Array[Bullet] = []
var _active: Array[Bullet] = []

var _enemy_available: Array[EnemyBullet] = []
var _enemy_active: Array[EnemyBullet] = []

var _wave_available: Array = []
var _wave_active: Array = []


func _ready() -> void:
	_wave_bullet_scene = load("res://scenes/entities/WaveBullet.tscn")
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
	for i: int in WAVE_POOL_SIZE:
		var bullet: Node = _wave_bullet_scene.instantiate()
		add_child(bullet)
		bullet.call("deactivate")
		_wave_available.append(bullet)


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


func get_wave_bullet(pos: Vector2, level: int, speed: float = 700.0, damage: int = 3) -> Node:
	if _wave_available.is_empty():
		push_warning("WaveBulletPool exhausted — consider increasing WAVE_POOL_SIZE")
		return null
	var bullet: Node = _wave_available.pop_back()
	bullet.call("initialize", pos, level, speed, damage)
	_wave_active.append(bullet)
	return bullet


func return_wave_bullet(bullet: Node) -> void:
	if bullet == null:
		return
	bullet.call("deactivate")
	_wave_active.erase(bullet)
	_wave_available.append(bullet)
