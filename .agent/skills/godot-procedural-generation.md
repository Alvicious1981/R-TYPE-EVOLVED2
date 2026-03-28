# Godot Procedural Generation — Chunk-Based Level Streaming

Patrón de referencia para generación procedural de niveles mediante chunks en Godot 4.6.
**Requerido para:** M22 (ChunkManager + LevelChunk Resource streaming)

---

## Problema que resuelve

Reemplazar encuentros scripted (timer-based) con niveles de longitud variable ensamblados a partir de bloques diseñados a mano, combinados aleatoriamente respetando restricciones de dificultad (`heat`) y bioma.

---

## Arquitectura Core

### LevelChunk Resource (data-driven)

```gdscript
# scripts/data/level_chunk.gd
class_name LevelChunk extends Resource
@export var chunk_id: StringName = &""
@export var chunk_type: StringName = &"breathing"  # "breathing"|"pressure"|"franchise"|"elite"|"transition"|"boss"
@export var spawn_waves: Array[Dictionary] = []     # [{enemy_id, count, formation, delay}]
@export var min_heat: int = 0
@export var max_heat: int = 4
@export var weight: float = 1.0
@export var duration_seconds: float = 15.0
@export var next_chunk_types: Array[StringName] = []  # transiciones permitidas
```

### ChunkManager (streaming controller)

Nodo registrado en `Main.tscn` o como autoload ligero:

```gdscript
# scripts/gameplay/chunk_manager.gd
extends Node

const MAX_ACTIVE_CHUNKS: int = 3  # Object Culling Directional — TDD §4.2

var _active_chunks: Array[LevelChunk] = []
var _chunk_pool: Array[LevelChunk] = []  # cargados desde resources/chunks/
var _current_heat: int = 0
var _current_biome: BiomeProfile

func load_chunk_pool(biome: BiomeProfile) -> void:
    _current_biome = biome
    _chunk_pool = biome.chunk_pool.duplicate()

func advance() -> void:
    if _active_chunks.size() >= MAX_ACTIVE_CHUNKS:
        _active_chunks.pop_front()
        EventBus.chunk_completed.emit(_active_chunks.front())
    var next: LevelChunk = _select_next_chunk()
    _active_chunks.append(next)
    EventBus.chunk_started.emit(next)

func _select_next_chunk() -> LevelChunk:
    var eligible: Array[LevelChunk] = _get_eligible_chunks()
    return _weighted_random(eligible)
```

---

## Algoritmo de Selección Weighted

```gdscript
func _weighted_random(pool: Array[LevelChunk]) -> LevelChunk:
    var total_weight: float = 0.0
    for chunk: LevelChunk in pool:
        total_weight += chunk.weight
    var roll: float = randf() * total_weight
    var cumulative: float = 0.0
    for chunk: LevelChunk in pool:
        cumulative += chunk.weight
        if roll <= cumulative:
            return chunk
    return pool.back()  # fallback — nunca debe ocurrir si pool no está vacío
```

---

## Filtrado por Heat y Bioma

```gdscript
func _get_eligible_chunks() -> Array[LevelChunk]:
    # Nunca seleccionar boss chunk aleatoriamente
    return _chunk_pool.filter(func(c: LevelChunk) -> bool:
        return c.min_heat <= _current_heat \
            and c.max_heat >= _current_heat \
            and c.chunk_type != &"boss"
    )
```

---

## Reglas de Diseño de Chunks

| Regla | Descripción |
|-------|-------------|
| Breathing primero | El primer chunk siempre es `breathing` — nunca empezar con presión |
| Boss siempre último | `boss` chunk no entra al pool aleatorio; se encadena explícitamente al final |
| Elite máx. 1 cada 3 | Evitar fatiga de dificultad — limitar por contador en ChunkManager |
| Transition entre biomas | Obligatorio al cambiar de `BiomeProfile` |
| Weight inversamente proporcional a dificultad | `breathing: 3.0`, `pressure: 2.0`, `franchise: 1.5`, `elite: 1.0` |

---

## Señales requeridas en EventBus

```gdscript
# autoloads/event_bus.gd — añadir en M22
signal chunk_started(chunk: LevelChunk)
signal chunk_completed(chunk: LevelChunk)
signal biome_transition_started(next_biome: BiomeProfile)
```

---

## Formato de spawn_waves (diccionario estándar)

```gdscript
# Ejemplo de LevelChunk "CrossFire" (pressure)
spawn_waves = [
    { "enemy_id": "torreta",  "count": 2, "formation": "top_bottom", "delay": 0.0 },
    { "enemy_id": "zangano",  "count": 4, "formation": "random",     "delay": 2.5 },
    { "enemy_id": "torreta",  "count": 1, "formation": "center",     "delay": 5.0 },
]
```

Formaciones disponibles: `"random"`, `"top_bottom"`, `"center"`, `"v_formation"`, `"corners"`.
El ChunkManager lee este array y delega al `SpawnController` (o al propio `EncounterDirector` refactorizado).

---

## Anti-patrones a evitar

- **No** más de `MAX_ACTIVE_CHUNKS` (3) en memoria simultánea
- **No** selección puramente aleatoria sin heat filter
- **No** boss chunk seleccionable por `_weighted_random`
- **No** instanciar chunks como hijos fijos de `Main.tscn`
- **No** lógica de oleadas dentro del ChunkManager (pertenece a `LevelChunk` data)
- **No** llamar `queue_free()` en bullets al destruir un chunk — usar `BulletPoolManager.return_bullet()`

---

## Integración con arquitectura existente

| Sistema existente | Relación con chunks |
|-------------------|---------------------|
| `BulletPoolManager` | No cambia — sigue siendo el único acceso a proyectiles |
| `EventBus` | Añadir 3 señales nuevas (ver arriba) |
| `RunManager` | `heat_level` alimenta el filtrado de chunks |
| `EncounterDirector` | Refactorizar: delegar spawn logic a ChunkManager, conservar FSM del Dreadnought |
| `BiomeProfile` | Contiene el `chunk_pool: Array[LevelChunk]` para filtrado |
