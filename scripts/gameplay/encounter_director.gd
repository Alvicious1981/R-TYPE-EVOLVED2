extends Node

signal run_complete

const _ENEMY_SCENE: PackedScene = preload("res://scenes/entities/EnemyBase.tscn")
const _ZANGANO_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-zangano.tres")
const _TORRETA_SCENE: PackedScene = preload("res://scenes/entities/EnemyTorreta.tscn")
const _TORRETA_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-torreta.tres")
const _DREADNOUGHT_SCENE: PackedScene = preload("res://scenes/entities/EnemyDreadnought.tscn")
const _DREADNOUGHT_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-dreadnought-explorer.tres")
const _BOSS_FLASH_SCENE: PackedScene = preload("res://scenes/ui/BossFlash.tscn")

const DREADNOUGHT_SPAWN_POS: Vector2 = Vector2(2100.0, 540.0)

const PHASE1_END: float = 15.0
const PHASE2_END: float = 30.0
const ENCOUNTER_END: float = 45.0
const PHASE1_INTERVAL: float = 1.8
const PHASE2_ALT_INTERVAL: float = 3.0
const PHASE3_INTERVAL: float = 2.5
const TRANSITION_DURATION: float = 2.0

var _elapsed: float = 0.0
var _phase: int = 1
var _timer1: float = 0.0
var _phase2_timer: float = 0.0
var _phase2_toggle: bool = false
var _timer3: float = 0.0
var _in_transition: bool = false
var _transition_timer: float = 0.0
var _done: bool = false
var _victory: bool = false
var _dreadnought_spawned: bool = false


func _ready() -> void:
	RunManager.reset()
	var boss_flash: CanvasLayer = _BOSS_FLASH_SCENE.instantiate() as CanvasLayer
	add_child(boss_flash)


func _process(delta: float) -> void:
	if _done:
		if _victory and Input.is_action_just_pressed("ui_restart"):
			get_tree().reload_current_scene()
		return

	var player: Player = get_parent().get_node_or_null("Player") as Player
	if player != null and player.is_dead:
		_done = true
		return

	_elapsed += delta

	if _elapsed >= ENCOUNTER_END:
		if not _dreadnought_spawned:
			_spawn_dreadnought()
		return

	if _in_transition:
		_transition_timer -= delta
		if _transition_timer <= 0.0:
			_in_transition = false
		return

	if _phase < 3 and _elapsed >= PHASE2_END:
		_phase = 3
		_timer3 = 0.0
		_start_transition()
		return
	elif _phase < 2 and _elapsed >= PHASE1_END:
		_phase = 2
		_phase2_timer = PHASE2_ALT_INTERVAL
		_phase2_toggle = false
		_start_transition()
		return

	_tick_phase1(delta)
	if _phase >= 2:
		_tick_phase2(delta)
	if _phase >= 3:
		_tick_phase3(delta)


func _start_transition() -> void:
	_in_transition = true
	_transition_timer = TRANSITION_DURATION


func _tick_phase1(delta: float) -> void:
	if _phase >= 3:
		return
	_timer1 -= delta
	if _timer1 <= 0.0:
		_timer1 = PHASE1_INTERVAL
		_spawn(Vector2(1950.0, randf_range(200.0, 880.0)), Vector2(-1.0, 0.0))


func _tick_phase2(delta: float) -> void:
	if _phase >= 3:
		return
	_phase2_timer -= delta
	if _phase2_timer <= 0.0:
		_phase2_timer = PHASE2_ALT_INTERVAL
		if _phase2_toggle:
			_spawn_torreta(Vector2(1700.0, randf_range(200.0, 880.0)))
		else:
			_spawn(Vector2(960.0, -60.0), Vector2(-0.3, 1.0).normalized())
		_phase2_toggle = not _phase2_toggle


func _tick_phase3(delta: float) -> void:
	_timer3 -= delta
	if _timer3 <= 0.0:
		_timer3 = PHASE3_INTERVAL
		_spawn(Vector2(1820.0, -60.0),  Vector2(-0.4, 1.0).normalized())
		_spawn(Vector2(100.0,  1140.0), Vector2(0.4, -1.0).normalized())


func _spawn(pos: Vector2, dir: Vector2) -> void:
	var enemy: EnemyBase = _ENEMY_SCENE.instantiate() as EnemyBase
	enemy.profile = _ZANGANO_PROFILE
	enemy.move_dir = dir
	get_parent().add_child(enemy)
	enemy.global_position = pos


func _spawn_torreta(pos: Vector2) -> void:
	var torreta: CharacterBody2D = _TORRETA_SCENE.instantiate() as CharacterBody2D
	torreta.set("profile", _TORRETA_PROFILE)
	get_parent().add_child(torreta)
	torreta.global_position = pos


func _spawn_dreadnought() -> void:
	_dreadnought_spawned = true
	var boss: EnemyDreadnought = _DREADNOUGHT_SCENE.instantiate() as EnemyDreadnought
	boss.profile = _DREADNOUGHT_PROFILE
	get_parent().add_child(boss)
	boss.global_position = DREADNOUGHT_SPAWN_POS
	boss.dreadnought_defeated.connect(_on_dreadnought_defeated)


func _on_dreadnought_defeated() -> void:
	_done = true
	_victory = true
	run_complete.emit()
