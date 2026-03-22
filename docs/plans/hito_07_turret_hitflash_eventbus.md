# Hito 07 — Hit Flash + Torreta Estática + EventBus

**Fecha:** 2026-03-19
**Agentes:** Planner → Worker → Validator
**Estado:** IMPLEMENTADO — Validado por Validator (2026-03-19)

---

## Skeleton of Thought

```
Sistemas a CREAR:
  assets/shaders/hit_flash.gdshader      → shader CanvasItem uniform bool hit_flash
  autoloads/event_bus.gd                 → señal enemy_destroyed(score_value, position)
  resources/enemies/enemy-torreta.tres   → EnemyProfile max_hp=3, point_value=30
  scenes/entities/enemy_torreta.gd       → estático, burst fan 3 balas ±15° cada 2s
  scenes/entities/EnemyTorreta.tscn      → CharacterBody2D, Polygon2D magenta

Sistemas a MODIFICAR:
  project.godot                          → añadir EventBus ANTES de RunManager
  autoloads/run_manager.gd               → _ready() conecta EventBus; migra a handler
  scenes/entities/enemy_base.gd          → EventBus.emit en muerte; hit flash Tween
  scripts/gameplay/encounter_director.gd → Torreta preloads; _torreta_timer; Phase 2

Datos ya existentes:
  scripts/data/enemy_profile.gd          → EnemyProfile.max_hp, .point_value ya existen
  autoloads/bullet_pool_manager.gd        → get_enemy_bullet() reutilizado por Torreta
  scenes/entities/EnemyBase.tscn          → patrón estructural para EnemyTorreta.tscn

Decisiones arquitectónicas:
  A — EnemyTorreta.tscn separada (no reutilizar EnemyBase): comportamiento distinto
  B — EventBus ANTES de RunManager en autoloads: RunManager._ready() conecta a él
  C — hit_flash en Polygon2D: shader CanvasItem escribe sobre COLOR (no TEXTURE)
  D — Tween solo cuando el enemigo sobrevive: queue_free() no necesita Tween
  E — _torreta_timer = 4.0 en transición de fase: primera torreta a los 19s
  F — Sin class_name en event_bus.gd: mismo patrón que bullet_pool_manager.gd
```

---

## Decisiones Arquitectónicas

**A — EnemyTorreta.tscn separada de EnemyBase.tscn:**
La torreta tiene comportamiento estructuralmente distinto: sin movimiento y con burst fan fire de 3 balas. Reutilizar EnemyBase.tscn con flags condicionales introduciría lógica ramificada en enemy_base.gd violando "Componentes Modulares" (CLAUDE.md §6). Un script separado permite que cada tipo evolucione independientemente.

**B — EventBus ANTES de RunManager en autoloads:**
RunManager._ready() llama `EventBus.enemy_destroyed.connect(...)`. Godot inicializa los autoloads en orden de aparición en project.godot. Si RunManager se inicializa primero, EventBus no existe aún y la conexión lanza error null en _ready().

**C — Hit flash en Polygon2D:**
Los visuales de los enemigos son Polygon2D (sin textura). El shader CanvasItem escribe sobre `COLOR` (el color de relleno). La condición `if (hit_flash) { COLOR = vec4(1,1,1,COLOR.a); }` sobreescribe el color original con blanco puro.

**D — Tween solo cuando el enemigo sobrevive:**
Si _current_hp <= 0, el nodo llama queue_free(). El Tween no se inicia porque el nodo desaparecerá. Solo se activa el Tween cuando hp > 0 tras el impacto.

**E — _torreta_timer inicializado a 4.0 en transición de fase:**
La transición Fase 1→2 ocurre a los 15s. Inicializar `_torreta_timer = 4.0` significa primera torreta a los 19s — tiempo para que el jugador procese el cambio de fase.

**F — Sin class_name en event_bus.gd:**
Los autoloads singleton se acceden por su nombre de nodo global. Añadir class_name puede causar conflictos de singleton documentados en commit 9fcd6ed.

---

## Archivos a Crear — Código Completo

### Archivo 1: `assets/shaders/hit_flash.gdshader`

```glsl
shader_type canvas_item;

uniform bool hit_flash = false;

void fragment() {
	if (hit_flash) {
		COLOR = vec4(1.0, 1.0, 1.0, COLOR.a);
	}
}
```

Nota: Para Polygon2D, `COLOR` ya tiene el color del vértice antes de entrar al fragment shader. No se usa `texture()` porque Polygon2D no tiene textura.

---

### Archivo 2: `autoloads/event_bus.gd`

```gdscript
extends Node

signal enemy_destroyed(score_value: int, position: Vector2)
```

---

### Archivo 3: `resources/enemies/enemy-torreta.tres`

```
[gd_resource type="Resource" script_class="EnemyProfile" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/enemy_profile.gd" id="1"]

[resource]
script = ExtResource("1")
id = "torreta"
max_hp = 3
point_value = 30
projectile_pattern = []
```

---

### Archivo 4: `scenes/entities/enemy_torreta.gd`

```gdscript
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
```

---

### Archivo 5: `scenes/entities/EnemyTorreta.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/entities/enemy_torreta.gd" id="1"]

[sub_resource type="RectangleShape2D" id="1"]
size = Vector2(32, 24)

[node name="EnemyTorreta" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 0
script = ExtResource("1")

[node name="EnemyVisual" type="Polygon2D" parent="."]
color = Color(0.8, 0.1, 0.8, 1)
polygon = PackedVector2Array(-16, -12, 16, -12, 16, 12, -16, 12)

[node name="EnemyCollision" type="CollisionShape2D" parent="."]
shape = SubResource("1")
```

---

## Archivos a Modificar — Diffs Completos

### Modificación 1: `project.godot` — sección [autoload]

**OLD:**
```ini
[autoload]

BulletPoolManager="*res://autoloads/bullet_pool_manager.gd"
RunManager="*res://autoloads/run_manager.gd"
```

**NEW:**
```ini
[autoload]

BulletPoolManager="*res://autoloads/bullet_pool_manager.gd"
EventBus="*res://autoloads/event_bus.gd"
RunManager="*res://autoloads/run_manager.gd"
```

---

### Modificación 2: `autoloads/run_manager.gd` — completo

**OLD:**
```gdscript
extends Node

signal score_changed(new_score: int)

var current_score: int = 0


func add_score(value: int) -> void:
	current_score += value
	score_changed.emit(current_score)


func reset() -> void:
	current_score = 0
	score_changed.emit(0)
```

**NEW:**
```gdscript
extends Node

signal score_changed(new_score: int)

var current_score: int = 0


func _ready() -> void:
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed(score_value: int, _position: Vector2) -> void:
	add_score(score_value)


func add_score(value: int) -> void:
	current_score += value
	score_changed.emit(current_score)


func reset() -> void:
	current_score = 0
	score_changed.emit(0)
```

---

### Modificación 3: `scenes/entities/enemy_base.gd` — completo

**OLD:**
```gdscript
class_name EnemyBase
extends CharacterBody2D

const MOVE_SPEED: float = 200.0
const FIRE_INTERVAL: float = 1.5
const BULLET_SPEED: float = 400.0
const BULLET_DAMAGE: int = 1
const MUZZLE_OFFSET: Vector2 = Vector2(-16.0, 0.0)

@export var profile: EnemyProfile
@export var move_dir: Vector2 = Vector2(-1.0, 0.0)

var _current_hp: int = 0
var _fire_timer: float = 0.0


func _ready() -> void:
	_current_hp = profile.max_hp
	_fire_timer = randf_range(0.3, FIRE_INTERVAL)


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
		RunManager.add_score(profile.point_value)
		queue_free()
```

**NEW:**
```gdscript
class_name EnemyBase
extends CharacterBody2D

const MOVE_SPEED: float = 200.0
const FIRE_INTERVAL: float = 1.5
const BULLET_SPEED: float = 400.0
const BULLET_DAMAGE: int = 1
const MUZZLE_OFFSET: Vector2 = Vector2(-16.0, 0.0)

const _HIT_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")

@export var profile: EnemyProfile
@export var move_dir: Vector2 = Vector2(-1.0, 0.0)

var _current_hp: int = 0
var _fire_timer: float = 0.0
var _hit_material: ShaderMaterial

@onready var _visual: Polygon2D = $EnemyVisual


func _ready() -> void:
	_current_hp = profile.max_hp
	_fire_timer = randf_range(0.3, FIRE_INTERVAL)
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
		EventBus.enemy_destroyed.emit(profile.point_value, global_position)
		queue_free()
		return
	_hit_material.set_shader_parameter("hit_flash", true)
	var tween: Tween = create_tween()
	tween.tween_callback(_clear_flash).set_delay(0.05)


func _clear_flash() -> void:
	if is_instance_valid(self):
		_hit_material.set_shader_parameter("hit_flash", false)
```

---

### Modificación 4: `scripts/gameplay/encounter_director.gd` — completo

**NEW (archivo completo):**
```gdscript
extends Node

signal run_complete

const _ENEMY_SCENE: PackedScene = preload("res://scenes/entities/EnemyBase.tscn")
const _ZANGANO_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-zangano.tres")
const _TORRETA_SCENE: PackedScene = preload("res://scenes/entities/EnemyTorreta.tscn")
const _TORRETA_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-torreta.tres")

const PHASE1_END: float = 15.0
const PHASE2_END: float = 30.0
const ENCOUNTER_END: float = 45.0
const PHASE1_INTERVAL: float = 1.8
const PHASE2_INTERVAL: float = 2.2
const PHASE3_INTERVAL: float = 2.5
const TORRETA_INTERVAL: float = 8.0

var _elapsed: float = 0.0
var _phase: int = 1
var _timer1: float = 0.0
var _timer2: float = 0.0
var _timer3: float = 0.0
var _torreta_timer: float = 0.0
var _done: bool = false
var _victory: bool = false


func _ready() -> void:
	RunManager.reset()


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
		_done = true
		_victory = true
		run_complete.emit()
		return

	if _phase < 3 and _elapsed >= PHASE2_END:
		_phase = 3
		_timer3 = 0.0
	elif _phase < 2 and _elapsed >= PHASE1_END:
		_phase = 2
		_timer2 = PHASE2_INTERVAL
		_torreta_timer = 4.0

	_tick_phase1(delta)
	if _phase >= 2:
		_tick_phase2(delta)
	if _phase >= 3:
		_tick_phase3(delta)


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
	_timer2 -= delta
	if _timer2 <= 0.0:
		_timer2 = PHASE2_INTERVAL
		_spawn(Vector2(960.0, -60.0), Vector2(-0.3, 1.0).normalized())
	_torreta_timer -= delta
	if _torreta_timer <= 0.0:
		_torreta_timer = TORRETA_INTERVAL
		_spawn_torreta(Vector2(1700.0, randf_range(200.0, 880.0)))


func _tick_phase3(delta: float) -> void:
	_timer3 -= delta
	if _timer3 <= 0.0:
		_timer3 = PHASE3_INTERVAL
		for _i: int in 3:
			_spawn(Vector2(randf_range(1400.0, 1900.0), -60.0), Vector2(-0.5, 1.0).normalized())
		for _i: int in 3:
			_spawn(Vector2(randf_range(1400.0, 1900.0), 1140.0), Vector2(-0.5, -1.0).normalized())


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
```

---

## Orden de Ejecución para el Worker

```
PASO 1: Crear assets/shaders/hit_flash.gdshader
        (debe existir antes de que enemy_base.gd y enemy_torreta.gd lo preloaden)

PASO 2: Crear autoloads/event_bus.gd
        (debe existir como archivo antes de registrarse en project.godot)

PASO 3: Modificar project.godot
        (insertar EventBus ENTRE BulletPoolManager y RunManager)

PASO 4: Crear resources/enemies/enemy-torreta.tres
        (debe existir antes de que encounter_director.gd lo preload)

PASO 5: Crear scenes/entities/enemy_torreta.gd
        (debe existir antes de que EnemyTorreta.tscn lo referencie)

PASO 6: Crear scenes/entities/EnemyTorreta.tscn
        (depende del script del Paso 5)

PASO 7: Modificar autoloads/run_manager.gd
        (añadir _ready() con conexión a EventBus; añadir _on_enemy_destroyed)

PASO 8: Modificar scenes/entities/enemy_base.gd
        (añadir shader, hit flash Tween; migrar a EventBus.emit)

PASO 9: Modificar scripts/gameplay/encounter_director.gd
        (añadir torreta preloads, _torreta_timer, _tick_phase2 torreta, _spawn_torreta)
```

---

## Double-Tap Verification Checklist

### `assets/shaders/hit_flash.gdshader`
- [ ] `shader_type canvas_item;` en línea 1
- [ ] `uniform bool hit_flash = false;` declarado
- [ ] `void fragment()` presente
- [ ] `if (hit_flash) { COLOR = vec4(1.0, 1.0, 1.0, COLOR.a); }` correcto

### `autoloads/event_bus.gd`
- [ ] Sin `class_name` (igual que bullet_pool_manager.gd)
- [ ] `extends Node`
- [ ] `signal enemy_destroyed(score_value: int, position: Vector2)` presente
- [ ] Sin variables de estado ni lógica adicional

### `project.godot`
- [ ] Orden exacto: BulletPoolManager → EventBus → RunManager
- [ ] `EventBus="*res://autoloads/event_bus.gd"` (con asterisco)
- [ ] Sin duplicados

### `resources/enemies/enemy-torreta.tres`
- [ ] `script_class="EnemyProfile"` en header
- [ ] `id = "torreta"`
- [ ] `max_hp = 3`
- [ ] `point_value = 30`
- [ ] `projectile_pattern = []`

### `scenes/entities/enemy_torreta.gd`
- [ ] Sin `class_name`
- [ ] `extends CharacterBody2D`
- [ ] `BURST_INTERVAL = 2.0` y `BURST_ANGLES_DEG = [-15.0, 0.0, 15.0]`
- [ ] `@export var profile: EnemyProfile`
- [ ] `_HIT_SHADER: Shader = preload(...)` con ruta correcta
- [ ] `_ready()`: inicializa hp, timer, crea ShaderMaterial, asigna shader y material al visual
- [ ] `_physics_process()`: solo fire timer, SIN move_and_slide()
- [ ] `_fire_burst()`: 3 balas con BulletPoolManager.get_enemy_bullet()
- [ ] `take_damage()`: emite EventBus.enemy_destroyed en muerte; return; Tween solo si sobrevive
- [ ] `_clear_flash()`: guard `is_instance_valid(self)`

### `scenes/entities/EnemyTorreta.tscn`
- [ ] Script: `res://scenes/entities/enemy_torreta.gd`
- [ ] `collision_layer = 4` (Chasis_Hostil)
- [ ] `collision_mask = 0`
- [ ] `EnemyVisual` tipo `Polygon2D`, color magenta `Color(0.8, 0.1, 0.8, 1)`
- [ ] `EnemyCollision` tipo `CollisionShape2D`, RectangleShape2D(32, 24)

### `autoloads/run_manager.gd`
- [ ] `func _ready() -> void:` con `EventBus.enemy_destroyed.connect(_on_enemy_destroyed)`
- [ ] `func _on_enemy_destroyed(score_value: int, _position: Vector2) -> void:` tipado
- [ ] `_on_enemy_destroyed` llama `add_score(score_value)`
- [ ] `add_score()` y `reset()` sin cambios respecto al original

### `scenes/entities/enemy_base.gd`
- [ ] `const _HIT_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")`
- [ ] `var _hit_material: ShaderMaterial` declarado
- [ ] `@onready var _visual: Polygon2D = $EnemyVisual`
- [ ] `_ready()`: tres líneas de ShaderMaterial al final
- [ ] `take_damage()`: `RunManager.add_score()` ELIMINADO
- [ ] `take_damage()`: `EventBus.enemy_destroyed.emit()` presente
- [ ] `take_damage()`: `return` después de `queue_free()`
- [ ] `take_damage()`: Tween solo en el bloque después del return
- [ ] `_clear_flash()`: con guard `is_instance_valid(self)`
- [ ] `class_name EnemyBase` MANTENIDO

### `scripts/gameplay/encounter_director.gd`
- [ ] `_TORRETA_SCENE` y `_TORRETA_PROFILE` preloaded
- [ ] `const TORRETA_INTERVAL: float = 8.0`
- [ ] `var _torreta_timer: float = 0.0`
- [ ] `_torreta_timer = 4.0` en la transición `elif _phase < 2`
- [ ] `_tick_phase2()`: bloque `_torreta_timer` añadido
- [ ] `_spawn_torreta(pos: Vector2)` con `torreta.set("profile", ...)`

---

## Clean Floor Protocol

**Prueba visible en menos de 60 segundos:**

1. F5 → juego arranca sin errores rojos en Output
2. Score "SC  0" visible en HUD al inicio
3. Disparar al primer Zángano → flash blanco visible → score sube a 10
4. Esperar hasta ~19s → figura magenta (Torreta) aparece en zona derecha
5. Torreta no se mueve
6. Torreta dispara burst de 3 balas en abanico cada 2s
7. Impacto 1 a Torreta → flash blanco visible (no muere)
8. Impacto 2 a Torreta → flash blanco visible (no muere)
9. Impacto 3 a Torreta → Torreta desaparece → score +30
10. R tras muerte → score vuelve a 0

---

## Criterios de Aceptación

| # | Criterio | Verificación |
|---|---------|-------------|
| CA-1 | Zángano destruido → +10 en HUD | Visual |
| CA-2 | Torreta aparece en Fase 2 (~19s) | Visual — figura magenta |
| CA-3 | Torreta no se mueve | Observar 5s — posición X fija |
| CA-4 | Torreta dispara 3 balas en abanico cada 2s | Contar balas; ángulos distintos |
| CA-5 | Torreta requiere 3 impactos | HP 3 → muere al tercero |
| CA-6 | Hit flash visible en impactos no letales | Flash blanco 0.05s en impactos 1 y 2 |
| CA-7 | Torreta destruida → +30 en HUD | Score sube 30 al matar torreta |
| CA-8 | Score fluye por EventBus (no llamada directa) | Código: enemy_base emite EventBus, NOT RunManager.add_score() |
| CA-9 | R reinicia → score 0 | Input R → "SC  0" |
| CA-10 | F5 sin errores rojos en 45s completos | Output panel |

---

## Fuera de Scope (NO implementar)

- Miniboss, HUD nuevo grande, AudioManager completo
- Tienda, guardado, roguelite, Force module
- Refactors fuera de los archivos listados
- Hit flash en el jugador (ya tiene su propio death flash)
- Señales de jugador o Force en EventBus (solo enemy_destroyed en M7)
- Torreta adherida a geometría, múltiples patrones de disparo, Wave Cannon
