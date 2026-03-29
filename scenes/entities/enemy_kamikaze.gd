class_name EnemyKamikaze
extends EnemyBase

## M21 — Kamikaze: persigue al jugador en línea recta, ignorando waypoints.
## Alta velocidad, baja vida, daño elevado al contacto.

const KAMIKAZE_SPEED: float = 420.0
const CONTACT_DAMAGE: int = 4
const ROTATE_SPEED: float = 6.0

var _player: Node2D = null


func _ready() -> void:
	super._ready()
	# Buscar el Player en el grupo para robustez entre escenas
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node2D


func _physics_process(delta: float) -> void:
	# Sobreescribe el movimiento de la base: persecución directa
	if is_instance_valid(_player):
		var chase_dir: Vector2 = (_player.global_position - global_position).normalized()
		velocity = chase_dir * KAMIKAZE_SPEED
	else:
		# Sin jugador detectado: avanza en la dirección por defecto de la base
		velocity = move_dir * KAMIKAZE_SPEED

	move_and_slide()

	# Culling fuera de pantalla
	if global_position.x < -200.0 or global_position.x > 2100.0 \
			or global_position.y < -200.0 or global_position.y > 1280.0:
		queue_free()
		return

	# NO llama a _handle_fire() — el kamikaze no dispara, daña al contacto


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(CONTACT_DAMAGE)
		_spawn_explosion()
		EventBus.enemy_destroyed.emit(profile.point_value, global_position)
		queue_free()
