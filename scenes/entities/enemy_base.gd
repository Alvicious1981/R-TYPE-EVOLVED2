class_name EnemyBase
extends CharacterBody2D

const MOVE_SPEED: float = 200.0
const FIRE_INTERVAL: float = 1.5
const BULLET_SPEED: float = 400.0
const BULLET_DAMAGE: int = 1
const MUZZLE_OFFSET: Vector2 = Vector2(-16.0, 0.0)

const _HIT_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")
const _EXPLOSION_SCENE: PackedScene = preload("res://scenes/entities/ExplosionEffect.tscn")

@export var profile: EnemyProfile
@export var move_dir: Vector2 = Vector2(-1.0, 0.0)

var _current_hp: int = 0
var _fire_timer: float = 0.0
var _hit_material: ShaderMaterial

@onready var _visual: Sprite2D = $EnemyVisual


func _ready() -> void:
	_current_hp = profile.max_hp
	_fire_timer = randf_range(0.3, FIRE_INTERVAL)
	if profile.texture_path != "":
		_visual.texture = load(profile.texture_path) as Texture2D
		_visual.scale = profile.display_scale
	_hit_material = ShaderMaterial.new()
	_hit_material.shader = _HIT_SHADER
	_visual.material = _hit_material


func _physics_process(delta: float) -> void:
	velocity = move_dir * MOVE_SPEED
	move_and_slide()
	if global_position.x < -100.0 or global_position.y > 1180.0 or global_position.y < -100.0:
		queue_free()
		return
	_handle_fire(delta)


func _handle_fire(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = FIRE_INTERVAL
		_shoot()


func _shoot() -> void:
	var player: Node2D = get_parent().get_node_or_null("Player") as Node2D
	if player == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	var _b: EnemyBullet = BulletPoolManager.get_enemy_bullet(
		global_position + MUZZLE_OFFSET,
		dir,
		BULLET_SPEED,
		BULLET_DAMAGE
	)


func take_damage(amount: int) -> void:
	_current_hp -= amount
	if _current_hp <= 0:
		_spawn_explosion()
		LootTable.try_drop(global_position, get_parent())
		EventBus.enemy_destroyed.emit(profile.point_value, global_position)
		queue_free()
		return
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
