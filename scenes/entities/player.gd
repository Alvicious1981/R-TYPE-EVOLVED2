class_name Player extends CharacterBody2D

const MAX_HP: int = 3
const FIRE_RATE: float = 12.0
const BULLET_SPEED: float = 600.0
const BULLET_DAMAGE: int = 1
const MUZZLE_OFFSET: Vector2 = Vector2(20.0, 0.0)

@export var normal_speed: float = 400.0
@export var slow_speed: float = 180.0
@export var screen_margin: float = 24.0

@onready var screen_size: Vector2 = Vector2(1920.0, 1080.0)
@onready var _flash_overlay: ColorRect = $DeathLayer/FlashOverlay
@onready var _death_label: Label = $DeathLayer/DeathLabel

var is_dead: bool = false
var _current_hp: int = MAX_HP
var _fire_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if is_dead:
		if Input.is_action_just_pressed("ui_restart"):
			get_tree().reload_current_scene()
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed: float = slow_speed if Input.is_action_pressed("move_slow") else normal_speed
	velocity = input_dir * current_speed
	move_and_slide()
	_clamp_to_viewport()
	_handle_fire(delta)


func _clamp_to_viewport() -> void:
	global_position.x = clampf(global_position.x, screen_margin, screen_size.x - screen_margin)
	global_position.y = clampf(global_position.y, screen_margin, screen_size.y - screen_margin)


func _handle_fire(delta: float) -> void:
	_fire_timer -= delta
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire_timer = 1.0 / FIRE_RATE
		_shoot()


func _shoot() -> void:
	var _b: Bullet = BulletPoolManager.get_bullet(
		global_position + MUZZLE_OFFSET,
		Vector2.RIGHT,
		BULLET_SPEED,
		BULLET_DAMAGE
	)
	EventBus.player_shoot.emit()


func take_damage(amount: int) -> void:
	if is_dead:
		return
	_current_hp -= amount
	if _current_hp <= 0:
		_die()


func _die() -> void:
	is_dead = true
	_flash_overlay.visible = true
	_death_label.visible = true
	velocity = Vector2.ZERO
	EventBus.player_died.emit()
