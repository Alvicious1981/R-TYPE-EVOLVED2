class_name EnemyShielder
extends EnemyBase

## M21 — Shielder: baja velocidad, altísima vida.
## Dispara Spread Shot de 3 balas en abanico cada intervalo.

const SHIELDER_SPEED: float = 90.0
const SPREAD_FIRE_INTERVAL: float = 2.2
const SPREAD_BULLET_SPEED: float = 360.0
const SPREAD_BULLET_DAMAGE: int = 1
const SPREAD_ANGLES_DEG: Array[float] = [-20.0, 0.0, 20.0]
const SPREAD_MUZZLE_OFFSET: Vector2 = Vector2(-20.0, 0.0)

var _spread_timer: float = 0.0


func _ready() -> void:
	super._ready()
	# Escalonar el primer disparo para evitar sincronía con otros Shielders
	_spread_timer = randf_range(0.5, SPREAD_FIRE_INTERVAL)


func _physics_process(delta: float) -> void:
	# Movimiento lento lateral (hereda move_dir de la base)
	velocity = move_dir * SHIELDER_SPEED
	move_and_slide()

	# Culling
	if global_position.x < -200.0 or global_position.y > 1180.0 \
			or global_position.y < -100.0:
		queue_free()
		return

	# Spread Shot override — reemplaza _handle_fire() de la base
	_spread_timer -= delta
	if _spread_timer <= 0.0:
		_spread_timer = SPREAD_FIRE_INTERVAL
		_fire_spread()


## Dispara 3 proyectiles en abanico hacia la izquierda (-X).
func _fire_spread() -> void:
	for angle_deg: float in SPREAD_ANGLES_DEG:
		var dir: Vector2 = Vector2.LEFT.rotated(deg_to_rad(angle_deg))
		var _b: EnemyBullet = BulletPoolManager.get_enemy_bullet(
			global_position + SPREAD_MUZZLE_OFFSET,
			dir,
			SPREAD_BULLET_SPEED,
			SPREAD_BULLET_DAMAGE
		)
