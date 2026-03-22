extends CharacterBody2D

const BURST_INTERVAL: float = 2.0
const BULLET_SPEED: float = 380.0
const BULLET_DAMAGE: int = 1
const MUZZLE_OFFSET: Vector2 = Vector2(-16.0, 0.0)
const BURST_ANGLES_DEG: Array[float] = [-15.0, 0.0, 15.0]

const _HIT_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")

@export var profile: EnemyProfile

var _current_hp: int = 0
var _burst_timer: float = 0.0
var _hit_material: ShaderMaterial

@onready var _visual: Polygon2D = $EnemyVisual


func _ready() -> void:
	_current_hp = profile.max_hp
	_burst_timer = BURST_INTERVAL
	_hit_material = ShaderMaterial.new()
	_hit_material.shader = _HIT_SHADER
	_visual.material = _hit_material


func _physics_process(delta: float) -> void:
	_burst_timer -= delta
	if _burst_timer <= 0.0:
		_burst_timer = BURST_INTERVAL
		_fire_burst()


func _fire_burst() -> void:
	for angle_deg: float in BURST_ANGLES_DEG:
		var dir: Vector2 = Vector2.LEFT.rotated(deg_to_rad(angle_deg))
		var _b: EnemyBullet = BulletPoolManager.get_enemy_bullet(
			global_position + MUZZLE_OFFSET,
			dir,
			BULLET_SPEED,
			BULLET_DAMAGE
		)


func take_damage(amount: int) -> void:
	_current_hp -= amount
	if _current_hp <= 0:
		EventBus.enemy_destroyed.emit(profile.point_value, global_position)
		queue_free()
		return
	_hit_material.set_shader_parameter("hit_flash", true)
	var tween: Tween = create_tween()
	tween.tween_callback(_clear_flash).set_delay(0.05)


func _clear_flash() -> void:
	if is_instance_valid(self):
		_hit_material.set_shader_parameter("hit_flash", false)
