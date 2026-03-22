class_name EnemyDreadnought
extends CharacterBody2D

enum State { ENTERING, PHASE_1, TRANSITION, PHASE_2, DYING, DEAD }

const ENTER_SPEED: float = 80.0
const ENTER_TARGET_X: float = 1400.0
const PHASE1_FIRE_INTERVAL: float = 2.0
const PHASE2_FIRE_INTERVAL: float = 1.5
const PHASE1_BULLET_SPEED: float = 380.0
const PHASE2_BULLET_SPEED: float = 520.0
const PHASE1_ANGLES_DEG: Array[float] = [-20.0, 0.0, 20.0]
const PHASE2_ANGLES_DEG: Array[float] = [-30.0, -15.0, 0.0, 15.0, 30.0]
const TRANSITION_DURATION: float = 0.5
const DYING_DURATION: float = 1.0
const HP_PHASE2_RATIO: float = 0.5
const BULLET_DAMAGE: int = 1

const _HIT_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")
const _EXPLOSION_SCENE: PackedScene = preload("res://scenes/entities/ExplosionEffect.tscn")

signal dreadnought_defeated

@export var profile: EnemyProfile

var _current_hp: int = 0
var _state: State = State.ENTERING
var _fire_timer: float = 0.0
var _transition_timer: float = 0.0
var _dying_timer: float = 0.0
var _hit_material: ShaderMaterial

@onready var _visual: Polygon2D = $EnemyVisual


func _ready() -> void:
	_current_hp = profile.max_hp
	_hit_material = ShaderMaterial.new()
	_hit_material.shader = _HIT_SHADER
	_visual.material = _hit_material


func _process(delta: float) -> void:
	match _state:
		State.ENTERING:
			_tick_entering(delta)
		State.PHASE_1:
			_tick_firing(delta, PHASE1_FIRE_INTERVAL, PHASE1_ANGLES_DEG, PHASE1_BULLET_SPEED)
		State.TRANSITION:
			_tick_transition(delta)
		State.PHASE_2:
			_tick_firing(delta, PHASE2_FIRE_INTERVAL, PHASE2_ANGLES_DEG, PHASE2_BULLET_SPEED)
		State.DYING:
			_tick_dying(delta)
		State.DEAD:
			pass


func _tick_entering(delta: float) -> void:
	if global_position.x > ENTER_TARGET_X:
		global_position.x -= ENTER_SPEED * delta
	else:
		global_position.x = ENTER_TARGET_X
		_state = State.PHASE_1
		_fire_timer = PHASE1_FIRE_INTERVAL


func _tick_firing(delta: float, interval: float, angles: Array[float], speed: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = interval
		_fire_burst(angles, speed)


func _tick_transition(delta: float) -> void:
	_transition_timer -= delta
	if _transition_timer <= 0.0:
		_state = State.PHASE_2
		_fire_timer = PHASE2_FIRE_INTERVAL


func _tick_dying(delta: float) -> void:
	_dying_timer -= delta
	if _dying_timer <= 0.0:
		_state = State.DEAD
		_spawn_explosion()
		EventBus.enemy_destroyed.emit(profile.point_value, global_position)
		EventBus.boss_defeated.emit()
		dreadnought_defeated.emit()
		queue_free()


func _fire_burst(angles: Array[float], speed: float) -> void:
	for angle_deg: float in angles:
		var dir: Vector2 = Vector2.LEFT.rotated(deg_to_rad(angle_deg))
		var _b: EnemyBullet = BulletPoolManager.get_enemy_bullet(
			global_position + Vector2(-40.0, 0.0),
			dir,
			speed,
			BULLET_DAMAGE
		)


func take_damage(amount: int) -> void:
	if _state == State.ENTERING or _state == State.TRANSITION \
			or _state == State.DYING or _state == State.DEAD:
		return
	_current_hp -= amount
	_flash_hit()
	var hp_ratio: float = float(_current_hp) / float(profile.max_hp)
	if _state == State.PHASE_1 and hp_ratio <= HP_PHASE2_RATIO:
		_state = State.TRANSITION
		_transition_timer = TRANSITION_DURATION
		EventBus.boss_phase_changed.emit(2)
		return
	if _current_hp <= 0:
		_state = State.DYING
		_dying_timer = DYING_DURATION


func _flash_hit() -> void:
	_hit_material.set_shader_parameter("hit_flash", true)
	var tween: Tween = create_tween()
	tween.tween_callback(_clear_flash).set_delay(0.05)


func _clear_flash() -> void:
	if is_instance_valid(self):
		_hit_material.set_shader_parameter("hit_flash", false)


func _spawn_explosion() -> void:
	var pos: Vector2 = global_position
	var explosion: Node2D = _EXPLOSION_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = pos
