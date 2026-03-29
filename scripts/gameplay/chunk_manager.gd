extends Node

## M22 — ChunkDirector: orquesta la generación de terrenos infinitos y notifica al EncounterDirector qué oleadas generar.

@export var chunk_pool: Array[LevelChunk] = []

const SPAWN_X: float = 1920.0
const SCROLL_SPEED: float = 100.0
const CHUNK_WIDTH: float = 1920.0
const SPAWN_THRESHOLD_X: float = 200.0

var _last_chunk: Node2D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunks_spawned: int = 0

func _ready() -> void:
	_rng.randomize()
	if chunk_pool.is_empty():
		push_warning("[ChunkDirector] chunk_pool está vacío — añade resources .tres en el Inspector.")
		return
	# En el inicio, spawneamos un chunk inicial y otro preparado.
	_spawn_chunk_at(0.0)
	_spawn_chunk_at(SPAWN_X)


func _process(_delta: float) -> void:
	if chunk_pool.is_empty():
		return
	if not is_instance_valid(_last_chunk):
		# Si desaparece el último, forzamos uno nuevo.
		_spawn_chunk_at(SPAWN_X)
		return
		
	# Spawn cuando el borde derecho del último chunk entra a SPAWN_THRESHOLD_X
	if _last_chunk.global_position.x <= SPAWN_THRESHOLD_X:
		_spawn_chunk_at(_last_chunk.global_position.x + CHUNK_WIDTH)


func _spawn_chunk_at(x: float) -> void:
	var metadata: LevelChunk = _pick_random_chunk()
	
	if metadata != null and metadata.chunk_scene != null:
		var visual_chunk: Node2D = metadata.chunk_scene.instantiate() as Node2D
		get_parent().add_child(visual_chunk)
		visual_chunk.global_position = Vector2(x, 0.0)
		_last_chunk = visual_chunk
		
	_chunks_spawned += 1
	# Notificamos al EncounterDirector si es un nuevo chunk a procesar
	if metadata != null and _chunks_spawned > 1:
		# Ignoramos el chunk base inicial en x=0 para no lanzar oleadas instantáneas de golpe
		EventBus.chunk_started.emit(metadata)


func _pick_random_chunk() -> LevelChunk:
	# Sistema simplificado de peso y validación: por ahora aleatorio de todo el pool
	var idx: int = _rng.randi_range(0, chunk_pool.size() - 1)
	return chunk_pool[idx]
