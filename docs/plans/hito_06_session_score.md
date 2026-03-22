# Hito 06 — Score de Sesión Visible

**Fecha:** 2026-03-19
**Agentes:** Planner → Worker → Validator
**Estado:** PLAN APROBADO — pendiente implementación Worker

---

## Skeleton of Thought

```
Sistemas a CREAR:
  RunManager (autoload) → var current_score, signal score_changed, add_score(), reset()

Sistemas a MODIFICAR:
  project.godot → añadir RunManager bajo [autoload]
  enemy_base.gd → en take_damage(), antes de queue_free() → RunManager.add_score(profile.point_value)
  HUD.tscn → añadir nodo ScoreLabel (Label, anchors_preset=0, top-left)
  hud.gd → @onready ScoreLabel, _ready() conecta señal, _on_score_changed()
  encounter_director.gd → añadir _ready() con RunManager.reset()

Datos ya existentes:
  EnemyProfile.point_value: int = 0  ← campo ya declarado
  enemy-zangano.tres: point_value = 10  ← ya configurado

Decisión de reseteo:
  RunManager es Autoload → persiste al reload_current_scene()
  ELEGIDO: EncounterDirector._ready() llama RunManager.reset()
    Razón: EncounterDirector existe en Main y se reinicia con la escena.
    Es la forma más limpia sin introducir acoplamiento en player.gd.

Restricciones:
  Sin EventBus, sin combo, sin guardado, sin nuevos enemigos
  Sin class_name en run_manager.gd (igual que bullet_pool_manager.gd)
  Tipado estricto en todo GDScript nuevo
  ScoreLabel en top-left para no colisionar con TimerLabel (top-right)
```

---

## Archivos a Crear

### `autoloads/run_manager.gd`

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

Notas:
- Sin `class_name` — mismo patrón que `bullet_pool_manager.gd` para evitar conflicto de singleton Godot
- `score_changed` emite en ambas operaciones para que HUD siempre esté sincronizado
- `add_score` acepta `int` tipado

---

## Archivos a Modificar

### 1. `project.godot`

**Sección [autoload] — OLD:**
```ini
[autoload]

BulletPoolManager="*res://autoloads/bullet_pool_manager.gd"
```

**Sección [autoload] — NEW:**
```ini
[autoload]

BulletPoolManager="*res://autoloads/bullet_pool_manager.gd"
RunManager="*res://autoloads/run_manager.gd"
```

---

### 2. `scenes/entities/enemy_base.gd`

**Función take_damage — OLD:**
```gdscript
func take_damage(amount: int) -> void:
	_current_hp -= amount
	if _current_hp <= 0:
		queue_free()
```

**Función take_damage — NEW:**
```gdscript
func take_damage(amount: int) -> void:
	_current_hp -= amount
	if _current_hp <= 0:
		RunManager.add_score(profile.point_value)
		queue_free()
```

Nota: `RunManager.add_score()` ANTES de `queue_free()` — `profile` sigue válido en ese momento.

---

### 3. `scenes/ui/HUD.tscn`

Añadir nodo ScoreLabel ENTRE TimerLabel y RunCompleteLabel:

```
[node name="ScoreLabel" type="Label" parent="."]
anchors_preset = 0
offset_left = 14.0
offset_top = 14.0
offset_right = 220.0
offset_bottom = 54.0
text = "SC  0"
theme_override_font_sizes/font_size = 26
```

- `anchors_preset = 0` es top-left (espejo de `anchors_preset = 1` del TimerLabel)
- Sin `horizontal_alignment` → alineación izquierda por defecto

---

### 4. `scenes/ui/hud.gd`

**OLD:**
```gdscript
extends CanvasLayer

const ENCOUNTER_END: float = 45.0

@onready var _timer_label: Label = $TimerLabel
@onready var _run_complete_label: Label = $RunCompleteLabel


func _process(_delta: float) -> void:
	...

func show_run_complete() -> void:
	...
```

**NEW — añadir:**
- `@onready var _score_label: Label = $ScoreLabel`
- `func _ready() -> void:` con `RunManager.score_changed.connect(_on_score_changed)`
- `func _on_score_changed(new_score: int) -> void:` con `_score_label.text = "SC  %d" % new_score`

---

### 5. `scripts/gameplay/encounter_director.gd`

Añadir función `_ready()` después del bloque de variables:

```gdscript
func _ready() -> void:
	RunManager.reset()
```

Justificación: RunManager es Autoload persistente. Al presionar R se recarga la escena y EncounterDirector._ready() se ejecuta de nuevo, zerificando el score exactamente una vez por partida.

---

## Orden de Ejecución para el Worker

```
PASO 1: Crear autoloads/run_manager.gd
PASO 2: Modificar project.godot — añadir RunManager bajo [autoload]
PASO 3: Modificar scripts/gameplay/encounter_director.gd — añadir _ready()
PASO 4: Modificar scenes/entities/enemy_base.gd — add_score() en take_damage()
PASO 5: Modificar scenes/ui/HUD.tscn — añadir nodo ScoreLabel
PASO 6: Modificar scenes/ui/hud.gd — añadir @onready, _ready(), _on_score_changed()
```

---

## Double-Tap Verification Checklist

### `autoloads/run_manager.gd`
- [ ] Sin `class_name`
- [ ] `extends Node`
- [ ] `signal score_changed(new_score: int)` con tipo
- [ ] `var current_score: int = 0`
- [ ] `func add_score(value: int) -> void`
- [ ] `func reset() -> void`
- [ ] `score_changed.emit()` en ambas funciones
- [ ] Indentación con tabs

### `project.godot`
- [ ] `RunManager="*res://autoloads/run_manager.gd"` bajo `[autoload]`
- [ ] Prefijo `*` presente
- [ ] BulletPoolManager sin modificar

### `scripts/gameplay/encounter_director.gd`
- [ ] `func _ready() -> void:` con `-> void`
- [ ] `RunManager.reset()` dentro de `_ready()`
- [ ] `_process()` sin cambios

### `scenes/entities/enemy_base.gd`
- [ ] `RunManager.add_score(profile.point_value)` ANTES de `queue_free()`
- [ ] `queue_free()` sigue presente

### `scenes/ui/HUD.tscn`
- [ ] Nodo `ScoreLabel` de tipo `Label`, parent `"."`
- [ ] `anchors_preset = 0`
- [ ] `text = "SC  0"` (dos espacios)
- [ ] `font_size = 26`
- [ ] UID sin cambios: `uid://b_hud_m5_2026`

### `scenes/ui/hud.gd`
- [ ] `@onready var _score_label: Label = $ScoreLabel`
- [ ] `func _ready() -> void:` con conexión de señal
- [ ] `func _on_score_changed(new_score: int) -> void:` tipado
- [ ] `_process()` y `show_run_complete()` sin cambios

---

## Clean Floor Protocol

- [ ] F5 sin errores rojos en Output
- [ ] ScoreLabel visible top-left con "SC  0" al inicio
- [ ] Matar Zángano → "SC  10" en HUD
- [ ] R reinicia → "SC  0"
- [ ] TimerLabel top-right no afectado
- [ ] "RUN COMPLETE — Press R" sigue funcionando
- [ ] FPS ≥ 55 en Fase 3

---

## Criterios de Aceptación

| # | Criterio | Verificación |
|---|---------|-------------|
| CA-1 | F5 sin errores rojos | Panel Output |
| CA-2 | ScoreLabel "SC  0" al inicio | Visual |
| CA-3 | Matar 1 Zángano → "SC  10" | Visual |
| CA-4 | Matar 5 Zánganos → "SC  50" | Visual |
| CA-5 | R en victoria → "SC  0" | Input R |
| CA-6 | R en derrota → "SC  0" | Input R |
| CA-7 | TimerLabel countdown intacto | Visual |
| CA-8 | "RUN COMPLETE" sigue apareciendo | Visual |
| CA-9 | Vertical slice 45s sin regresión | Play completo |
| CA-10 | FPS ≥ 55 en Fase 3 | Profiler |

---

## Archivos Out of Scope (NO tocar)

- `autoloads/bullet_pool_manager.gd`
- `scripts/data/`
- `resources/`
- `scenes/entities/Bullet.tscn`
- `scenes/entities/EnemyBullet.tscn`
- `scenes/entities/EnemyBase.tscn`
- `scenes/entities/Player.tscn`
- `scenes/entities/bullet.gd`
- `scenes/entities/enemy_bullet.gd`
- `scenes/entities/player.gd`
- `scenes/main/Main.tscn`
- `scenes/main/background.gd`
