class_name WaveBullet extends Area2D

## Daño base por nivel de carga (L1, L2, L3)
const DAMAGE_BY_LEVEL: Array[int] = [3, 6, 12]
## Penetraciones máximas por nivel (-1 = ilimitado)
const MAX_HITS_BY_LEVEL: Array[int] = [2, -1, -1]
## collision_mask por nivel: L1/L2 solo capa 3; L3 capa 3+4 (también destruye Municion_Biomecanica)
const MASK_BY_LEVEL: Array[int] = [4, 4, 12]
## Color del proyectil por nivel
const COLOR_BY_LEVEL: Array[Color] = [
	Color(0.4, 0.9, 1.0, 1.0),  # L1 — cian claro
	Color(0.1, 0.5, 1.0, 1.0),  # L2 — azul
	Color(1.0, 0.3, 0.9, 1.0),  # L3 — magenta
]
## Escala del polígono visual por nivel
const SCALE_BY_LEVEL: Array[Vector2] = [
	Vector2(1.0, 1.0),
	Vector2(2.5, 1.3),
	Vector2(4.0, 4.0),
]

var _speed: float = 700.0
var _damage: int = 3
var _charge_level: int = 1
var _hit_count: int = 0
var _max_hits: int = 2

@onready var _collision: CollisionShape2D = $BulletCollision
@onready var _polygon: Polygon2D = $BulletPolygon

## Formas pre-instanciadas en _ready() para evitar GC por disparo
var _shape_l1: RectangleShape2D
var _shape_l2: RectangleShape2D
var _shape_l3: CircleShape2D


func _ready() -> void:
	_shape_l1 = RectangleShape2D.new()
	_shape_l1.size = Vector2(32.0, 8.0)
	_shape_l2 = RectangleShape2D.new()
	_shape_l2.size = Vector2(80.0, 10.0)
	_shape_l3 = CircleShape2D.new()
	_shape_l3.radius = 48.0
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func initialize(pos: Vector2, level: int, speed: float, damage: int) -> void:
	_charge_level = clampi(level, 1, 3)
	_speed = speed
	_damage = damage
	_hit_count = 0
	_max_hits = MAX_HITS_BY_LEVEL[_charge_level - 1]
	collision_mask = MASK_BY_LEVEL[_charge_level - 1]
	_apply_level_appearance(_charge_level)
	global_position = pos
	show()
	set_deferred("monitoring", true)


func deactivate() -> void:
	set_deferred("monitoring", false)
	hide()
	global_position = Vector2(-9999.0, -9999.0)
	_hit_count = 0


func _apply_level_appearance(level: int) -> void:
	match level:
		1: _collision.shape = _shape_l1
		2: _collision.shape = _shape_l2
		3: _collision.shape = _shape_l3
	_polygon.scale = SCALE_BY_LEVEL[level - 1]
	_polygon.color = COLOR_BY_LEVEL[level - 1]


func _physics_process(delta: float) -> void:
	if not visible:
		return
	global_position.x += _speed * delta
	if global_position.x > 1980.0 or global_position.x < -100.0:
		# call() evita resolución estática circular (BulletPoolManager preloada esta escena)
		BulletPoolManager.call("return_wave_bullet", self)


func _on_area_entered(area: Area2D) -> void:
	if not visible:
		return
	# L3: destruye proyectiles enemigos sin contar como impacto de penetración
	if area is EnemyBullet:
		if _charge_level == 3:
			BulletPoolManager.call("return_enemy_bullet", area)
		return
	if area.has_method("take_damage"):
		area.take_damage(_damage)
		_register_hit()


func _on_body_entered(body: Node2D) -> void:
	if not visible:
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage)
		_register_hit()


func _register_hit() -> void:
	_hit_count += 1
	if _max_hits > 0 and _hit_count >= _max_hits:
		BulletPoolManager.call("return_wave_bullet", self)
