# Plan — Milestone 3: Primer Enemigo Funcional (Zángano)

## Objetivo Jugable

Un Zángano entra desde la derecha, se mueve hacia la izquierda. El jugador le dispara.
El enemigo recibe daño y muere. Primer loop completo: amenaza entra → jugador reacciona → amenaza eliminada.

---

## Archivos a crear / modificar

| Archivo | Estado | Qué hace |
|---------|--------|----------|
| `resources/enemies/enemy-zangano.tres` | NUEVO | EnemyProfile: max_hp=1, point_value=10, id="zangano" |
| `scenes/entities/enemy_base.gd` | NUEVO | CharacterBody2D: movimiento izq., HP desde profile, take_damage(), muere en 0 |
| `scenes/entities/EnemyBase.tscn` | NUEVO | CharacterBody2D + visual (rectángulo naranja) + CollisionShape2D Layer 3 |
| `scenes/main/spawner.gd` | NUEVO | Timer → spawn Zángano en x=1950, y aleatorio [200–880] cada 2s |
| `scenes/main/Main.tscn` | MODIFICAR | Añadir Spawner como hijo |
| `scenes/entities/bullet.gd` | SIN CAMBIO | Ya tiene mask=4 → detecta Layer 3. `_on_area_entered` → `take_damage()` ya funciona |

---

## Tabla de Collision Layers

| Entidad | collision_layer (bitmask) | collision_mask (bitmask) | Razón |
|---------|--------------------------|--------------------------|-------|
| Player | 1 (Layer 1) | 0 | M3: jugador no detecta nada todavía |
| Bullet | 2 (Layer 2) | 4 (Layer 3) | YA CONFIGURADO — detecta Chasis_Hostil |
| EnemyBase | 4 (Layer 3) | 0 | M3: enemigo no detecta nada — solo recibe |

> **Regla de oro**: Bullet.tscn ya tiene `collision_mask=4`. El enemigo con `collision_layer=4`
> es automáticamente detectado por las balas sin tocar bullet.gd.

---

## Orden de Implementación

1. `enemy-zangano.tres` — primero, para que enemy_base.gd pueda precargar
2. `enemy_base.gd` — lógica del enemigo
3. `EnemyBase.tscn` — escena que referencia enemy_base.gd
4. `spawner.gd` — preloads EnemyBase.tscn + enemy-zangano.tres
5. `Main.tscn` — añadir nodo Spawner con spawner.gd

---

## Firmas de Funciones

### enemy_base.gd
```gdscript
class_name EnemyBase
extends CharacterBody2D

const MOVE_SPEED: float = 200.0

@export var profile: EnemyProfile

var _current_hp: int = 0

func _ready() -> void
func _physics_process(delta: float) -> void   # mueve izquierda + auto-destroy en x<-100
func take_damage(amount: int) -> void          # reduce _current_hp, queue_free si <=0
```

### spawner.gd
```gdscript
extends Node

const _ENEMY_SCENE: PackedScene = preload("res://scenes/entities/EnemyBase.tscn")
const _ZANGANO_PROFILE: EnemyProfile = preload("res://resources/enemies/enemy-zangano.tres")

@onready var _timer: Timer = $SpawnTimer

func _ready() -> void      # configura timer
func _on_spawn_timer_timeout() -> void   # instancia + posiciona + add_child
```

---

## Fuera de Scope

- Enemigo dispara
- Jugador recibe daño
- Score / EventBus
- HUD
- Hit flash (recomendado pero no bloqueante)
- FSM (el movimiento lineal es suficiente para M3)

---

## Prueba Visible Obligatoria

F5 → hold fire → Zánganos entran desde la derecha → se mueven hacia la izquierda →
bala los alcanza → desaparecen tras 1 impacto. Nuevos Zánganos siguen apareciendo.
Output limpio (cero errores).

---

## Criterios de Aceptación

- [ ] Zángano aparece y se mueve hacia la izquierda
- [ ] HP leído de `enemy-zangano.tres` (no hardcodeado en gd)
- [ ] Zángano muere tras `max_hp` impactos (1 bala para Zángano)
- [ ] Bala desaparece al impactar (retorna al pool)
- [ ] Zánganos se eliminan solos si salen por el borde izquierdo
- [ ] Cero errores en Output

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `profile` null en `_ready()` → crash en `_current_hp = profile.max_hp` | Spawner asigna profile ANTES de add_child |
| Layer bitmask mal puesto → bala no detecta enemigo | Verificar collision_layer=4 en EnemyBase.tscn inspector |
| Enemigos acumulados si no salen por borde | `if global_position.x < -100: queue_free()` en _physics_process |
