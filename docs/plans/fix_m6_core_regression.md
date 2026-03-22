# Fix — Regresión Core M6: No Disparo + No Daño al Jugador

**Fecha:** 2026-03-19
**Agentes:** Planner → Worker → Validator
**Estado:** FIX APLICADO Y VERIFICADO (2026-03-19)

## Verificación de Estado Actual (inspección de código fuente)

| Check | Resultado |
|---|---|
| `player.gd` línea 33: `_handle_fire(delta)` llamado en `_physics_process` | ✅ PRESENTE |
| `player.gd` línea 43: `Input.is_action_pressed("fire")` | ✅ PRESENTE |
| `player.gd` línea 49: `BulletPoolManager.get_bullet(...)` | ✅ PRESENTE |
| `player.gd` línea 57: `take_damage(amount: int) -> void` | ✅ PRESENTE |
| `player.gd` línea 65: `_die() -> void` con overlay y label | ✅ PRESENTE |
| `Player.tscn`: `$DeathLayer/FlashOverlay` existe | ✅ PRESENTE |
| `Player.tscn`: `$DeathLayer/DeathLabel` existe | ✅ PRESENTE |
| `Player.tscn`: `collision_layer = 1` (Jugador_Nucleo) | ✅ correcto |
| `EnemyBullet.tscn`: `collision_mask = 1` (detecta Jugador_Nucleo) | ✅ correcto |
| `enemy_bullet.gd`: `body_entered.connect(_on_body_entered)` | ✅ PRESENTE |
| `project.godot`: acción "fire" definida (Space + Z) | ✅ PRESENTE |
| `project.godot`: acción "ui_restart" definida (R) | ✅ PRESENTE |
| `RunManager` registrado como Autoload | ✅ PRESENTE |
| `BulletPoolManager` registrado como Autoload | ✅ PRESENTE |

**Conclusión**: El Worker implementó el fix. `player.gd` actual tiene 70 líneas con toda la lógica correcta.
El plan fue escrito cuando `player.gd` tenía solo 23 líneas (sin fire ni take_damage).

**Nota MCP**: El servidor MCP está activo (v0.2.8, puerto 6505) pero el editor Godot
no estaba conectado al momento de esta verificación. La inspección se realizó directamente
sobre los archivos fuente del proyecto.

---

## Skeleton of Thought

```
Síntomas:
  1. Espacio no dispara
  2. Balas enemigas no dañan al jugador

Inspección de collision layers (verificada en .tscn):
  Player:      collision_layer=1 (Jugador_Nucleo), collision_mask=0
  Bullet:      collision_layer=2 (Municion_Aliada), collision_mask=4 (Chasis_Hostil)
  EnemyBase:   collision_layer=4 (Chasis_Hostil), collision_mask=0
  EnemyBullet: collision_layer=8 (Municion_Biomecanica), collision_mask=1 (Jugador_Nucleo)

  → Colisiones configuradas CORRECTAMENTE. No hay bug de layers.

Inspección de Input Map (project.godot):
  "fire" action: physical_keycode=32 (Space), physical_keycode=90 (Z) → DEFINIDO CORRECTAMENTE

Inspección de player.gd (23 líneas):
  → _physics_process: solo movimiento, SIN _handle_fire()
  → SIN función take_damage()
  → SIN función _die()
  → SIN fire timer, SIN muzzle offset, SIN llamada a BulletPoolManager

Inspección de enemy_bullet.gd:
  → _on_body_entered: body.has_method("take_damage") → FALSE porque player.gd
     no tiene esta función → NO se aplica daño

Root Cause 1 (no dispara):
  player.gd no tiene lógica de disparo. La acción "fire" existe en project.godot
  pero nadie la lee.

Root Cause 2 (no daño):
  player.gd no tiene take_damage(). EnemyBullet sí detecta al Player
  (collision mask/layer correctos) pero has_method("take_damage") = false.

Archivos out-of-scope confirmados:
  - bullet_pool_manager.gd: correcto, no toca
  - bullet.gd / enemy_bullet.gd: collision y callbacks correctos, no tocar
  - EnemyBase.tscn / enemy_base.gd: correctos, no tocar
  - project.godot: input map correcto, no tocar
  - HUD.tscn / hud.gd: M6 intacto, no tocar
  - run_manager.gd: M6 intacto, no tocar

Fix mínimo:
  UN SOLO archivo a modificar: scenes/entities/player.gd
  Añadir las funciones que faltan.
```

---

## Causa Raíz Exacta

| # | Síntoma | Causa raíz | Archivo | Línea faltante |
|---|---------|-----------|---------|----------------|
| 1 | No dispara | `_physics_process` no llama `_handle_fire()`. Funciones `_handle_fire()` y `_shoot()` no existen | `player.gd` | — (funciones inexistentes) |
| 2 | No daño | `player.gd` no tiene `take_damage()`. `EnemyBullet._on_body_entered` llama `body.has_method("take_damage")` → false | `player.gd` | — (función inexistente) |

---

## Datos del Proyecto (usados en la implementación)

```
weapon-vulcan.tres:
  fire_rate = 12.0   → FIRE_RATE: float = 12.0 → interval = 1.0/12.0 ≈ 0.083s
  damage = 1         → BULLET_DAMAGE: int = 1
  projectile_speed = 600.0 → BULLET_SPEED: float = 600.0

Player.tscn nodos existentes:
  $DeathLayer/FlashOverlay  ← ColorRect rojo
  $DeathLayer/DeathLabel    ← Label "DESTROYED — Press R"

Collision layers:
  Player layer 1 (Jugador_Nucleo) = bit 0 = valor 1
  Bullet mask 4 = bit 2 = Layer 3 (Chasis_Hostil) = EnemyBase ✓
  EnemyBullet mask 1 = bit 0 = Layer 1 (Jugador_Nucleo) = Player ✓

Input action "fire":
  Space (physical_keycode=32) y Z (physical_keycode=90) → usar is_action_pressed

encounter_director.gd:
  Detecta player.is_dead → para spawn
  Maneja R-key solo en victoria (_victory=true)
  → Player.gd debe manejar R-key en muerte (mostrando DeathLabel "DESTROYED")
```

---

## player.gd — Archivo Completo Resultante

```gdscript
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
```

---

## Análisis de la implementación

### Fire Logic
- `FIRE_RATE = 12.0` → `1/12 ≈ 0.083s` entre disparos (12 balas/segundo, R-Type clásico)
- `_fire_timer` se decrementa cada frame; cuando `<= 0` y se presiona "fire" → dispara y resetea
- `is_action_pressed` (no `just_pressed`) → fuego automático sostenido
- `MUZZLE_OFFSET = Vector2(20, 0)` → bala sale desde la punta de la nave (nave mide ~18px en X)
- `_b` con underscore → variable no usada con nombre indicativo (convención GDScript)

### Take Damage + Death
- `MAX_HP = 3` → muere a 3 impactos (verificado contra M4 plan)
- Guard `if is_dead: return` en take_damage → immunity post-muerte (no double-kill)
- `_die()`: sets is_dead → EncounterDirector lo detecta y para spawn
- `_die()`: muestra FlashOverlay (rojo) + DeathLabel ("DESTROYED — Press R")
- `velocity = Vector2.ZERO` en _die() → nave queda quieta

### Restart en muerte
- Cuando `is_dead = true`, `_physics_process` detecta `ui_restart` (R key) → `reload_current_scene()`
- EncounterDirector maneja R solo en victoria → player maneja R en muerte → cobertura completa

---

## Orden de Ejecución para el Worker

```
PASO 1: Leer player.gd actual (confirmar estado de 23 líneas)
PASO 2: Reescribir player.gd completo con el contenido del plan
PASO 3: Double-Tap Verification — leer player.gd y confirmar todos los checks
PASO 4: Clean Floor Protocol
```

---

## Double-Tap Verification Checklist

### `player.gd`
- [ ] `class_name Player extends CharacterBody2D` — sin cambio en primera línea
- [ ] `const MAX_HP: int = 3`
- [ ] `const FIRE_RATE: float = 12.0`
- [ ] `const BULLET_SPEED: float = 600.0`
- [ ] `const BULLET_DAMAGE: int = 1`
- [ ] `const MUZZLE_OFFSET: Vector2 = Vector2(20.0, 0.0)`
- [ ] `@onready var _flash_overlay: ColorRect = $DeathLayer/FlashOverlay`
- [ ] `@onready var _death_label: Label = $DeathLayer/DeathLabel`
- [ ] `var is_dead: bool = false` — en línea 19 (misma posición relativa)
- [ ] `var _current_hp: int = MAX_HP`
- [ ] `var _fire_timer: float = 0.0`
- [ ] `_physics_process` guarda `if is_dead:` como primera operación
- [ ] `_physics_process` llama `_handle_fire(delta)` como última operación
- [ ] `_handle_fire(delta: float) -> void` — tipado
- [ ] `Input.is_action_pressed("fire")` — no just_pressed (fuego automático)
- [ ] `_fire_timer = 1.0 / FIRE_RATE` — reset correcto
- [ ] `_shoot() -> void` — tipado retorno
- [ ] `BulletPoolManager.get_bullet(...)` — 4 parámetros: pos, dir, speed, damage
- [ ] `take_damage(amount: int) -> void` — tipado
- [ ] Guard `if is_dead: return` en take_damage
- [ ] `_die() -> void` — tipado
- [ ] `is_dead = true` en _die()
- [ ] `_flash_overlay.visible = true` en _die()
- [ ] `_death_label.visible = true` en _die()
- [ ] Ningún otro archivo modificado

---

## Clean Floor Protocol

- [ ] F5 sin errores rojos en Output
- [ ] Espacio dispara balas amarillas desde la nave
- [ ] Balas golpean Zánganos y los destruyen
- [ ] Zánganos muertos suman 10 al score (M6 intacto)
- [ ] Recibir 3 disparos enemigos → FlashOverlay rojo + "DESTROYED — Press R"
- [ ] Presionar R tras muerte → score vuelve a 0, juego reinicia
- [ ] "RUN COMPLETE" sigue apareciendo en victoria
- [ ] FPS ≥ 55 en Fase 3

---

## Criterios de Aceptación

| CA | Criterio | Verificación |
|----|---------|-------------|
| CA-1 | F5 sin errores rojos | Output panel |
| CA-2 | Espacio dispara | Visual — balas amarillas aparecen |
| CA-3 | Balas destruyen Zánganos | Visual — Zángano desaparece al impacto |
| CA-4 | 3 impactos enemigos → muerte | Visual — overlay rojo |
| CA-5 | R reinicia tras muerte | Input R |
| CA-6 | Score M6 sigue subiendo | Visual — SC sube al matar |
| CA-7 | Score se zerifica al reiniciar | Visual — SC vuelve a 0 |
| CA-8 | Prueba completa < 30s | Cronómetro |

---

## Archivos Out of Scope (NO tocar)

- `autoloads/bullet_pool_manager.gd`
- `autoloads/run_manager.gd`
- `scenes/entities/bullet.gd`
- `scenes/entities/enemy_bullet.gd`
- `scenes/entities/enemy_base.gd`
- `scripts/gameplay/encounter_director.gd`
- `scenes/ui/hud.gd`
- `scenes/ui/HUD.tscn`
- `project.godot`
- `resources/`
- `scripts/data/`
