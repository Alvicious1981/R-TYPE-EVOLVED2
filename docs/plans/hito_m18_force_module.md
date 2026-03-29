# M18 — Force Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el Módulo Force satélite con 3 estados (ATTACHED_FRONT, ATTACHED_BACK, FREE_ROAM), escudo real contra balas enemigas, y daño por contacto a enemigos.

**Architecture:**
ForceModule es un `CharacterBody2D` en Layer 5 que se mueve como hijo top-level del Player.
EnemyBullet (Area2D) detecta Force vía `body_entered` al añadir Layer 5 a su mask.
Un hijo `DamageArea` (Area2D, mask Layer 3) detecta colisión con enemigos para infligir daño.
Movement en ATTACHED usa `lerp`; en FREE_ROAM usa velocidad manual + rebote contra bordes.

**Tech Stack:** GDScript 4.6 tipado estricto, CharacterBody2D, Area2D, `set_as_top_level(true)`

---

## Archivos

| Acción | Ruta |
|--------|------|
| CREATE | `scenes/entities/Force.tscn` |
| CREATE | `scenes/entities/force_module.gd` |
| CREATE | `resources/force/force-config-default.tres` |
| MODIFY | `autoloads/event_bus.gd` |
| MODIFY | `scenes/entities/EnemyBullet.tscn` (collision_mask: añadir Layer 5) |
| MODIFY | `scenes/entities/player.gd` (instanciar Force + input force_toggle) |
| MODIFY | `project.godot` (añadir input action `force_toggle`) |

---

## Task 1: Señales en EventBus

**Files:**
- Modify: `autoloads/event_bus.gd`

- [ ] **Step 1: Añadir señales al EventBus**

Abrir `autoloads/event_bus.gd` y añadir al final:

```gdscript
signal force_state_changed(new_state: int)
signal force_hit_enemy(damage: int)
```

Resultado completo del archivo:
```gdscript
extends Node

signal enemy_destroyed(score_value: int, position: Vector2)
signal boss_phase_changed(new_phase: int)
signal boss_defeated()
signal player_shoot()
signal player_died()
signal wave_charge_started()
signal wave_charge_changed(level: int)
signal wave_cannon_fired(level: int, power: float)
signal wave_cannon_cancelled()
signal force_state_changed(new_state: int)
signal force_hit_enemy(damage: int)
```

- [ ] **Step 2: Verificar en editor**

Abrir Godot. Sin errores de parse en `autoloads/event_bus.gd`. La escena compila.

- [ ] **Step 3: Commit**

```bash
git add autoloads/event_bus.gd
git commit -m "feat(M18): add force_state_changed and force_hit_enemy signals to EventBus"
```

---

## Task 2: ForceConfig default resource

**Files:**
- Create: `resources/force/force-config-default.tres`

- [ ] **Step 1: Crear directorio y resource**

Crear el archivo `resources/force/force-config-default.tres` con contenido:

```
[gd_resource type="Resource" script_class="ForceConfig" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/force_config.gd" id="1_force"]

[resource]
script = ExtResource("1_force")
mode = 0
energy_drain_rate = 0.0
bounce_charge_gain = 0.5
```

> `bounce_charge_gain = 0.5` reservado para Kinetic Synergy (M23) — no activo en M18.

- [ ] **Step 2: Commit**

```bash
git add resources/force/force-config-default.tres
git commit -m "feat(M18): add default ForceConfig resource"
```

---

## Task 3: Input action force_toggle

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Leer project.godot para localizar la sección [input]**

Buscar el bloque `[input]` en `project.godot`. Tendrá entradas como:
```
fire={
"deadzone": 0.5,
"events": [...]
}
```

- [ ] **Step 2: Añadir force_toggle al final del bloque [input]**

Insertar esta entrada en la sección `[input]` de `project.godot`:

```
force_toggle={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":113,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":4,"pressure":0.0,"pressed":false,"script":null)
]
}
```

> Tecla Q (keycode 81) + L1 del gamepad (button_index 4).

- [ ] **Step 3: Verificar en Godot**

Abrir Godot → Project → Project Settings → Input Map. Debe aparecer `force_toggle` con Q y L1.

- [ ] **Step 4: Commit**

```bash
git add project.godot
git commit -m "feat(M18): add force_toggle input action (Q / L1)"
```

---

## Task 4: EnemyBullet collision mask — Layer 5

**Files:**
- Modify: `scenes/entities/EnemyBullet.tscn`

> **Por qué:** EnemyBullet es Area2D. Su `body_entered` sólo detecta CharacterBody2D en las capas de su `collision_mask`. Actualmente tiene mask=1 (Jugador_Nucleo). Añadir Layer 5 (Modulo_Tactico_Force, bit 4 = valor 16) hace que detecte al Force y lo destruya sin que deba modificarse la lógica del bullet.
> **Layer 5 bit mask value:** Layer 5 = bit index 4 → valor decimal 16. Layer 1|Layer 5 = 1+16 = **17**.

- [ ] **Step 1: Leer EnemyBullet.tscn**

Leer `scenes/entities/EnemyBullet.tscn` y localizar la línea con `collision_mask`.

- [ ] **Step 2: Cambiar collision_mask de 1 a 17**

En la sección del nodo raíz (EnemyBullet Area2D), cambiar:
```
collision_mask = 1
```
a:
```
collision_mask = 17
```

> Esto añade Layer 5 a la detección sin cambiar ninguna lógica GDScript.
> El método `_on_body_entered` ya maneja correctamente al Force: `has_method("take_damage")` → false en ForceModule → no inflige daño, pero el bullet retorna al pool normalmente. ✓

- [ ] **Step 3: Verificar en Godot**

Abrir Godot. EnemyBullet inspector muestra `Collision Mask: 1, 5` (Layer 1 y Layer 5 activos).

- [ ] **Step 4: Commit**

```bash
git add scenes/entities/EnemyBullet.tscn
git commit -m "feat(M18): add Layer 5 to EnemyBullet collision mask for Force shield"
```

---

## Task 5: ForceModule — script

**Files:**
- Create: `scenes/entities/force_module.gd`

- [ ] **Step 1: Crear el script `force_module.gd`**

```gdscript
class_name ForceModule
extends CharacterBody2D

## Módulo Force satélite. Tres estados: ATTACHED_FRONT, ATTACHED_BACK, FREE_ROAM.
## Actúa como escudo contra balas enemigas e inflige daño a enemigos por contacto.

enum ForceState { ATTACHED_FRONT, ATTACHED_BACK, FREE_ROAM }

const FRONT_OFFSET: Vector2 = Vector2(48.0, 0.0)
const BACK_OFFSET: Vector2 = Vector2(-48.0, 0.0)
const LERP_SPEED: float = 12.0
const FREE_ROAM_SPEED: float = 300.0
const SCREEN_MARGIN: float = 20.0
const SCREEN_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const CONTACT_DAMAGE: int = 1
const DAMAGE_COOLDOWN: float = 0.6

var _state: ForceState = ForceState.ATTACHED_FRONT
var _player: CharacterBody2D
var _free_roam_velocity: Vector2 = Vector2(FREE_ROAM_SPEED, 0.0)
var _damage_cooldowns: Dictionary = {}

@onready var _damage_area: Area2D = $DamageArea


func _ready() -> void:
	set_as_top_level(true)
	_player = get_parent() as CharacterBody2D
	global_position = _player.global_position + FRONT_OFFSET
	_damage_area.body_entered.connect(_on_damage_area_body_entered)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_tick_damage_cooldowns(delta)

	if Input.is_action_just_pressed("force_toggle"):
		_cycle_state()

	match _state:
		ForceState.ATTACHED_FRONT, ForceState.ATTACHED_BACK:
			_process_attached(delta)
		ForceState.FREE_ROAM:
			_process_free_roam(delta)


func _cycle_state() -> void:
	match _state:
		ForceState.ATTACHED_FRONT:
			_state = ForceState.FREE_ROAM
			_free_roam_velocity = Vector2(FREE_ROAM_SPEED, 0.0)
		ForceState.FREE_ROAM:
			_state = ForceState.ATTACHED_BACK
		ForceState.ATTACHED_BACK:
			_state = ForceState.ATTACHED_FRONT
	EventBus.force_state_changed.emit(_state)


func _process_attached(delta: float) -> void:
	var offset: Vector2 = FRONT_OFFSET if _state == ForceState.ATTACHED_FRONT else BACK_OFFSET
	var target: Vector2 = _player.global_position + offset
	global_position = global_position.lerp(target, LERP_SPEED * delta)


func _process_free_roam(delta: float) -> void:
	global_position += _free_roam_velocity * delta
	# Rebote contra bordes de pantalla
	if global_position.x <= SCREEN_MARGIN or global_position.x >= SCREEN_SIZE.x - SCREEN_MARGIN:
		_free_roam_velocity.x = -_free_roam_velocity.x
	if global_position.y <= SCREEN_MARGIN or global_position.y >= SCREEN_SIZE.y - SCREEN_MARGIN:
		_free_roam_velocity.y = -_free_roam_velocity.y
	global_position = global_position.clamp(
		Vector2(SCREEN_MARGIN, SCREEN_MARGIN),
		SCREEN_SIZE - Vector2(SCREEN_MARGIN, SCREEN_MARGIN)
	)


func _on_damage_area_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	if _damage_cooldowns.has(body):
		return
	body.take_damage(CONTACT_DAMAGE)
	_damage_cooldowns[body] = DAMAGE_COOLDOWN
	EventBus.force_hit_enemy.emit(CONTACT_DAMAGE)


func _tick_damage_cooldowns(delta: float) -> void:
	for key: Variant in _damage_cooldowns.keys():
		_damage_cooldowns[key] -= delta
		if _damage_cooldowns[key] <= 0.0:
			_damage_cooldowns.erase(key)
```

- [ ] **Step 2: Verificar parsing**

Sin errores de tipado. Verificar que `class_name ForceModule` no está en un autoload (es una escena regular — está permitido).

---

## Task 6: Force.tscn — escena

**Files:**
- Create: `scenes/entities/Force.tscn`

> Esta tarea usa los MCP tools de Godot para crear la escena, o se crea el archivo .tscn directamente.

- [ ] **Step 1: Crear Force.tscn con el siguiente contenido**

Crear `scenes/entities/Force.tscn`:

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scenes/entities/force_module.gd" id="1_script"]

[sub_resource type="RectangleShape2D" id="1_shape"]
size = Vector2(20, 20)

[sub_resource type="RectangleShape2D" id="2_damage_shape"]
size = Vector2(22, 22)

[node name="ForceModule" type="CharacterBody2D"]
collision_layer = 16
collision_mask = 0
script = ExtResource("1_script")

[node name="ForceSprite" type="ColorRect" parent="."]
offset_left = -10.0
offset_top = -10.0
offset_right = 10.0
offset_bottom = 10.0
color = Color(0.2, 0.8, 1, 0.9)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1_shape")

[node name="DamageArea" type="Area2D" parent="."]
collision_layer = 16
collision_mask = 4

[node name="DamageCollision" type="CollisionShape2D" parent="DamageArea"]
shape = SubResource("2_damage_shape")
```

> **Capas:**
> - `ForceModule` collision_layer = 16 (Layer 5 = bit 4 = 2^4 = 16) ✓
> - `ForceModule` collision_mask = 0 (sin colisión física propia — movimiento manual) ✓
> - `DamageArea` collision_layer = 16 (Layer 5) ✓
> - `DamageArea` collision_mask = 4 (Layer 3 = bit 2 = 2^2 = 4, Chasis_Hostil) ✓

- [ ] **Step 2: Abrir en Godot y verificar**

Godot debe mostrar ForceModule sin errores. Inspector debe mostrar:
- ForceModule: Layer 5 activo, sin Mask
- DamageArea: Layer 5 activo, Mask Layer 3 activo

- [ ] **Step 3: Commit escena + script**

```bash
git add scenes/entities/Force.tscn scenes/entities/force_module.gd
git commit -m "feat(M18): add ForceModule scene — 3 states, bullet shield, contact damage"
```

---

## Task 7: Player.gd — instanciar Force

**Files:**
- Modify: `scenes/entities/player.gd`

- [ ] **Step 1: Añadir preload y var al inicio de player.gd**

Tras las constantes existentes (después de la línea `const SHIP_CONFIG_PATHS`), añadir:

```gdscript
const _FORCE_SCENE: PackedScene = preload("res://scenes/entities/Force.tscn")
```

Tras las `@export var` existentes, añadir:

```gdscript
var _force_module: ForceModule
```

- [ ] **Step 2: Instanciar Force en _ready()**

Al final del bloque `_ready()` existente, añadir:

```gdscript
	_force_module = _FORCE_SCENE.instantiate() as ForceModule
	add_child(_force_module)
```

El `_ready()` completo resultante:

```gdscript
func _ready() -> void:
	var cfg: Resource = load(SHIP_CONFIG_PATHS[GameState.selected_ship_index]) as Resource
	if cfg != null:
		_ship_sprite.texture = load(cfg.get("texture_path") as String) as Texture2D
		_ship_sprite.scale = cfg.get("display_scale") as Vector2
	_force_module = _FORCE_SCENE.instantiate() as ForceModule
	add_child(_force_module)
```

- [ ] **Step 3: Verificar en Godot**

Ejecutar el proyecto. Force debe aparecer como cuadro cyan a la derecha de la nave desde el inicio.

- [ ] **Step 4: Commit**

```bash
git add scenes/entities/player.gd
git commit -m "feat(M18): player instantiates ForceModule on ready"
```

---

## Task 8: Verificación de combate en vivo

No hay tests unitarios en este stack — verificación manual mediante `mcp__godot__run_project`.

- [ ] **Test 1 — Force visible y adherido (ATTACHED_FRONT)**

Ejecutar proyecto, llegar a gameplay. Force (cuadro cyan) debe aparecer a la derecha de la nave y seguirla con suavidad (lerp).
Resultado esperado: Force sigue al Player con amortiguación elástica.

- [ ] **Test 2 — Ciclo de estados con tecla Q**

Pulsar Q:
1. Force entra en FREE_ROAM — se desplaza horizontalmente a 300px/s y rebota en bordes.
2. Pulsar Q de nuevo — Force se adhiere a la parte trasera (izquierda) del Player.
3. Pulsar Q — Force vuelve a ATTACHED_FRONT.

- [ ] **Test 3 — Escudo contra balas enemigas**

Con Force en ATTACHED_FRONT, dejar que un Torreta dispare hacia el jugador colocándose a la derecha. Las balas enemigas deben desaparecer al tocar el Force sin dañar al Player.
Resultado esperado: balas retornan al pool (desaparecen); Player no recibe daño.

- [ ] **Test 4 — Daño por contacto a enemigos**

Mover la nave hasta que Force entre en contacto con un Zángano. Zángano debe morir (1 HP).
Para Torretas (3 HP): contacto repetido con cooldown debe reducir HP y activar hit flash.

- [ ] **Test 5 — Sin regresiones de Wave Cannon y Vulcan**

Vulcan y Wave Cannon L1/L2/L3 deben seguir funcionando sin cambios. Tecla Q no interfiere con fuego.

- [ ] **Test 6 — Force desaparece con Player muerto**

Al morir el Player, Force debe mantenerse visible (es hijo del árbol) pero su lógica queda detenida al no haber player válido. Sin errores NullRef.

- [ ] **Commit final de verificación**

```bash
git add -A
git commit -m "feat(M18): Force Module — shield, contact damage, 3 states — verified in combat"
```

---

## Notas de diseño para M18.2 (futuro)

- **Kinetic Synergy:** En FREE_ROAM, detectar colisión con Layer 6 (Terreno_Solido) vía `RayCast2D` y añadir carga a Wave Cannon mediante `EventBus.wave_charge_started`. `bounce_charge_gain` en `ForceConfig` ya está reservado.
- **Sprite real:** Reemplazar `ColorRect` por `Sprite2D` con textura de octógono cuando lleguen los assets de M19.
- **Modo DETACHED autónomo:** ForceConfig.mode = DETACHED para movimiento orbital programado.
- **Force en HUD:** Indicador de estado del Force (estado actual) en M22+.
