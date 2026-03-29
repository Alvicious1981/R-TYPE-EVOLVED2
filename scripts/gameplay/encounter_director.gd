extends Node

signal run_complete

# Escenas Base
const _ENEMY_SCENE: PackedScene = preload("res://scenes/entities/EnemyBase.tscn")
const _TORRETA_SCENE: PackedScene = preload("res://scenes/entities/EnemyTorreta.tscn")
const _DREADNOUGHT_SCENE: PackedScene = preload("res://scenes/entities/EnemyDreadnought.tscn")
const _KAMIKAZE_SCENE: PackedScene = preload("res://scenes/entities/EnemyKamikaze.tscn")
const _SHIELDER_SCENE: PackedScene = preload("res://scenes/entities/EnemyShielder.tscn")
const _BOSS_FLASH_SCENE: PackedScene = preload("res://scenes/ui/BossFlash.tscn")

# Profiles
const _ZANGANO_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-zangano.tres")
const _TORRETA_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-torreta.tres")
const _DREADNOUGHT_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-dreadnought-explorer.tres")
const _KAMIKAZE_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-kamikaze.tres")
const _SHIELDER_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-shielder.tres")

const DREADNOUGHT_SPAWN_POS: Vector2 = Vector2(2100.0, 540.0)

var _chunk_timers: Array[Dictionary] = []
var _chunks_completed: int = 0
var _boss_spawned: bool = false
var _done: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	RunManager.reset()
	var boss_flash: CanvasLayer = _BOSS_FLASH_SCENE.instantiate() as CanvasLayer
	add_child(boss_flash)
	
	EventBus.chunk_started.connect(_on_chunk_started)


func _on_chunk_started(chunk: Resource) -> void:
	if _boss_spawned or _done:
		return
		
	_chunks_completed += 1
	# M22: Sistema de spawn del jefe al bloque número 5
	if _chunks_completed >= 5:
		_spawn_dreadnought()
		return

	var l_chunk: LevelChunk = chunk as LevelChunk
	if l_chunk == null:
		return
	
	for w in l_chunk.spawn_waves:
		var w_dict: Dictionary = w as Dictionary
		_chunk_timers.append({
			"enemy_id": w_dict.get("enemy_id", "zangano"),
			"count": int(w_dict.get("count", 1)),
			"formation": w_dict.get("formation", "line"),
			"timer": float(w_dict.get("delay", 0.0))
		})


func _process(delta: float) -> void:
	if _done:
		return

	var player: Player = get_parent().get_node_or_null("Player") as Player
	if player != null and player.is_dead:
		_finish_run(false)
		return

	# Decrementar todos los timers de las oleadas del chunk actual
	for i in range(_chunk_timers.size() - 1, -1, -1):
		_chunk_timers[i].timer -= delta
		if _chunk_timers[i].timer <= 0.0:
			var w: Dictionary = _chunk_timers[i]
			_chunk_timers.remove_at(i)
			_spawn_formation(w.enemy_id, w.count, w.formation)


func _spawn_formation(e_id: String, count: int, formation: String) -> void:
	var base_y: float = _rng.randf_range(200.0, 880.0)
	var spacing_y: float = 120.0
	var spacing_x: float = 150.0
	
	for i in range(count):
		var pos: Vector2 = Vector2(2000.0, base_y)
		match formation:
			"line":
				pos.y = base_y + (i * spacing_y) - ((count - 1) * spacing_y * 0.5)
			"v":
				pos.x = 2000.0 + (abs((count - 1)*0.5 - i) * spacing_x)
				pos.y = base_y + (i * spacing_y) - ((count - 1) * spacing_y * 0.5)
			"zigzag":
				pos.x = 2000.0 + ((i % 2) * spacing_x)
				pos.y = base_y + (i * spacing_y) - ((count - 1) * spacing_y * 0.5)
				
		_spawn_single(e_id, pos)


func _spawn_single(e_id: String, pos: Vector2) -> void:
	# Dispatcher de enemigos
	match e_id:
		"zangano":
			var enemy: EnemyBase = _ENEMY_SCENE.instantiate() as EnemyBase
			enemy.profile = _ZANGANO_PROFILE
			enemy.move_dir = Vector2(-1.0, 0.0)
			get_parent().add_child(enemy)
			enemy.global_position = pos
		"torreta":
			var enemy: CharacterBody2D = _TORRETA_SCENE.instantiate() as CharacterBody2D
			enemy.set("profile", _TORRETA_PROFILE)
			get_parent().add_child(enemy)
			enemy.global_position = pos
		"kamikaze":
			var enemy: EnemyKamikaze = _KAMIKAZE_SCENE.instantiate() as EnemyKamikaze
			enemy.profile = _KAMIKAZE_PROFILE
			enemy.move_dir = Vector2(-1.0, 0.0)
			get_parent().add_child(enemy)
			enemy.global_position = pos
		"shielder":
			var enemy: EnemyShielder = _SHIELDER_SCENE.instantiate() as EnemyShielder
			enemy.profile = _SHIELDER_PROFILE
			enemy.move_dir = Vector2(-1.0, 0.0)
			get_parent().add_child(enemy)
			enemy.global_position = pos
#			print("Unknown enemy ID: ", e_id)

func _spawn_dreadnought() -> void:
	_boss_spawned = true
	var boss: EnemyDreadnought = _DREADNOUGHT_SCENE.instantiate() as EnemyDreadnought
	boss.profile = _DREADNOUGHT_PROFILE
	get_parent().add_child(boss)
	boss.global_position = DREADNOUGHT_SPAWN_POS
	boss.dreadnought_defeated.connect(_on_dreadnought_defeated)


func _on_dreadnought_defeated() -> void:
	_finish_run(true)


func _finish_run(victory: bool) -> void:
	_done = true
	GameState.final_score = RunManager.current_score
	GameState.run_victory = victory
	if victory:
		run_complete.emit()
	
	var delay: float = 2.0 if victory else 2.5
	await get_tree().create_timer(delay).timeout
	get_tree().change_scene_to_file("res://scenes/ui/ResultScreen.tscn")
