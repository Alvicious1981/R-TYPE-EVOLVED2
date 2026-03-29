class_name Player extends CharacterBody2D

enum State { NORMAL, CHARGING, DEAD }

const MAX_HP: int = 3
const BULLET_SPEED: float = 600.0
const BULLET_DAMAGE: int = 1
const MUZZLE_OFFSET: Vector2 = Vector2(20.0, 0.0)

## Tiempo mínimo de pulsación para activar el modo de carga (tap vs hold)
const CHARGE_START_THRESHOLD: float = 0.2
## Umbrales de carga en segundos para L1, L2, L3
const CHARGE_THRESHOLDS: Array[float] = [0.5, 1.0, 1.5]

const SHIP_CONFIG_PATHS: Array[String] = [
	"res://resources/ships/ship-config-1.tres",
	"res://resources/ships/ship-config-2.tres",
	"res://resources/ships/ship-config-3.tres",
	"res://resources/ships/ship-config-4.tres",
	"res://resources/ships/ship-config-5.tres",
]
const _FORCE_SCENE: PackedScene = preload("res://scenes/entities/Force.tscn")

@export var normal_speed: float = 400.0
@export var slow_speed: float = 180.0
@export var screen_margin: float = 24.0

var _force_module: ForceModule

@onready var screen_size: Vector2 = Vector2(1920.0, 1080.0)
@onready var _flash_overlay: ColorRect = $DeathLayer/FlashOverlay
@onready var _death_label: Label = $DeathLayer/DeathLabel
@onready var _ship_sprite: Sprite2D = $ShipSprite

## Compatibilidad externa: true cuando el jugador está muerto
var is_dead: bool:
	get: return _state == State.DEAD

var _state: State = State.NORMAL
var _current_hp: int = MAX_HP
## Tiempo acumulado de pulsación en estado NORMAL (para detectar tap vs hold)
var _hold_time: float = 0.0
## Tiempo acumulado de carga en estado CHARGING
var _charge_time: float = 0.0
var _charge_level: int = 0


func _ready() -> void:
	var cfg: Resource = load(SHIP_CONFIG_PATHS[GameState.selected_ship_index]) as Resource
	if cfg != null:
		_ship_sprite.texture = load(cfg.get("texture_path") as String) as Texture2D
		_ship_sprite.scale = cfg.get("display_scale") as Vector2
	_force_module = _FORCE_SCENE.instantiate() as ForceModule
	add_child(_force_module)


func _physics_process(delta: float) -> void:
	match _state:
		State.DEAD:
			pass
		State.NORMAL:
			_handle_movement()
			_handle_fire_normal(delta)
		State.CHARGING:
			_handle_movement()
			_handle_fire_charging(delta)


func _handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed: float = slow_speed if Input.is_action_pressed("move_slow") else normal_speed
	velocity = input_dir * current_speed
	move_and_slide()
	_clamp_to_viewport()


func _clamp_to_viewport() -> void:
	global_position.x = clampf(global_position.x, screen_margin, screen_size.x - screen_margin)
	global_position.y = clampf(global_position.y, screen_margin, screen_size.y - screen_margin)


## Estado NORMAL: tap dispara Vulcan, hold > 0.2s activa carga
func _handle_fire_normal(delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		_shoot()
		_hold_time = 0.0
	elif Input.is_action_pressed("fire"):
		_hold_time += delta
		if _hold_time >= CHARGE_START_THRESHOLD:
			_enter_charging()
	elif Input.is_action_just_released("fire"):
		_hold_time = 0.0


func _enter_charging() -> void:
	_state = State.CHARGING
	_hold_time = 0.0
	_charge_time = 0.0
	_charge_level = 0
	EventBus.wave_charge_started.emit()
	print("[WaveCannon] Charging started")


## Estado CHARGING: acumula nivel de carga; Vulcan bloqueado por diseño de FSM
func _handle_fire_charging(delta: float) -> void:
	_charge_time += delta

	var new_level: int = 0
	for i: int in CHARGE_THRESHOLDS.size():
		if _charge_time >= CHARGE_THRESHOLDS[i]:
			new_level = i + 1

	if new_level != _charge_level:
		_charge_level = new_level
		EventBus.wave_charge_changed.emit(_charge_level)
		print("[WaveCannon] Level reached: %d (%.2fs)" % [_charge_level, _charge_time])

	if Input.is_action_just_released("fire"):
		_release_wave_cannon()


func _shoot() -> void:
	var _b: Bullet = BulletPoolManager.get_bullet(
		global_position + MUZZLE_OFFSET,
		Vector2.RIGHT,
		BULLET_SPEED,
		BULLET_DAMAGE
	)
	EventBus.player_shoot.emit()


func _release_wave_cannon() -> void:
	_state = State.NORMAL

	if _charge_level == 0:
		EventBus.wave_cannon_cancelled.emit()
		print("[WaveCannon] Released too early — no fire (%.2fs)" % _charge_time)
		_charge_time = 0.0
		return

	var power: float = minf(_charge_time / CHARGE_THRESHOLDS[2], 1.0)
	EventBus.wave_cannon_fired.emit(_charge_level, power)
	print("[WaveCannon] FIRED level=%d | power=%.2f | t=%.2fs" % [_charge_level, power, _charge_time])

	var _w: Node = BulletPoolManager.get_wave_bullet(
		global_position + MUZZLE_OFFSET,
		_charge_level,
		700.0,
		WaveBullet.DAMAGE_BY_LEVEL[_charge_level - 1]
	)

	_charge_time = 0.0
	_charge_level = 0


func take_damage(amount: int) -> void:
	if _state == State.DEAD:
		return
	_current_hp -= amount
	if _current_hp <= 0:
		_die()


func _die() -> void:
	_state = State.DEAD
	_hold_time = 0.0
	_charge_time = 0.0
	_charge_level = 0
	_flash_overlay.visible = true
	_death_label.visible = true
	velocity = Vector2.ZERO
	EventBus.player_died.emit()
