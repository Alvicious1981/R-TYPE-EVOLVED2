class_name ForceModule
extends CharacterBody2D

## Módulo Force satélite. Tres estados: ATTACHED_FRONT, ATTACHED_BACK, FREE_ROAM.
## Actúa como escudo contra balas enemigas e inflige daño a enemigos por contacto.

enum ForceState { ATTACHED_FRONT, ATTACHED_BACK, FREE_ROAM }

const FRONT_OFFSET: Vector2 = Vector2(48.0, 0.0)
const BACK_OFFSET: Vector2 = Vector2(-48.0, 0.0)
const LERP_SPEED: float = 12.0
const FREE_ROAM_SPEED: float = 300.0
const SCREEN_MARGIN: float = 20.0
const SCREEN_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const CONTACT_DAMAGE: int = 1
const DAMAGE_COOLDOWN: float = 0.6

var _state: ForceState = ForceState.ATTACHED_FRONT
var _player: CharacterBody2D
var _free_roam_velocity: Vector2 = Vector2(FREE_ROAM_SPEED, 0.0)
var _damage_cooldowns: Dictionary = {}

@onready var _damage_area: Area2D = $DamageArea


func _ready() -> void:
	set_as_top_level(true)
	_player = get_parent() as CharacterBody2D
	global_position = _player.global_position + FRONT_OFFSET
	_damage_area.body_entered.connect(_on_damage_area_body_entered)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_tick_damage_cooldowns(delta)

	if Input.is_action_just_pressed("force_toggle"):
		_cycle_state()

	match _state:
		ForceState.ATTACHED_FRONT, ForceState.ATTACHED_BACK:
			_process_attached(delta)
		ForceState.FREE_ROAM:
			_process_free_roam(delta)


func _cycle_state() -> void:
	match _state:
		ForceState.ATTACHED_FRONT:
			_state = ForceState.FREE_ROAM
			_free_roam_velocity = Vector2(FREE_ROAM_SPEED, 0.0)
		ForceState.FREE_ROAM:
			_state = ForceState.ATTACHED_BACK
		ForceState.ATTACHED_BACK:
			_state = ForceState.ATTACHED_FRONT
	EventBus.force_state_changed.emit(_state)


func _process_attached(delta: float) -> void:
	var offset: Vector2 = FRONT_OFFSET if _state == ForceState.ATTACHED_FRONT else BACK_OFFSET
	var target: Vector2 = _player.global_position + offset
	global_position = global_position.lerp(target, LERP_SPEED * delta)


func _process_free_roam(delta: float) -> void:
	global_position += _free_roam_velocity * delta
	# Rebote contra bordes de pantalla
	if global_position.x <= SCREEN_MARGIN or global_position.x >= SCREEN_SIZE.x - SCREEN_MARGIN:
		_free_roam_velocity.x = -_free_roam_velocity.x
	if global_position.y <= SCREEN_MARGIN or global_position.y >= SCREEN_SIZE.y - SCREEN_MARGIN:
		_free_roam_velocity.y = -_free_roam_velocity.y
	global_position = global_position.clamp(
		Vector2(SCREEN_MARGIN, SCREEN_MARGIN),
		SCREEN_SIZE - Vector2(SCREEN_MARGIN, SCREEN_MARGIN)
	)


func _on_damage_area_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	if _damage_cooldowns.has(body):
		return
	body.take_damage(CONTACT_DAMAGE)
	_damage_cooldowns[body] = DAMAGE_COOLDOWN
	EventBus.force_hit_enemy.emit(CONTACT_DAMAGE)


func _tick_damage_cooldowns(delta: float) -> void:
	for key: Variant in _damage_cooldowns.keys():
		_damage_cooldowns[key] -= delta
		if _damage_cooldowns[key] <= 0.0:
			_damage_cooldowns.erase(key)
