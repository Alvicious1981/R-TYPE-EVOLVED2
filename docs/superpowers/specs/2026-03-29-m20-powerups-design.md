# M20 — Power-Ups In-Run: Design Spec
**Fecha:** 2026-03-29
**Estado:** Aprobado
**Hito:** M20 (Fase 2 — post-M19)
**Dependencias:** M19 completado, `UpgradeData` existente en `scripts/data/upgrade_data.gd`

---

## Objetivo

Implementar el sistema de drops de power-ups temporales durante la run. Los enemigos tienen un 15% de probabilidad de soltar un power-up al morir. El jugador los recoge por contacto y sus efectos son temporales (con duración en segundos). El `RunManager` gestiona los timers de expiración.

---

## 1. Datos — `UpgradeData` ampliado

Extender `scripts/data/upgrade_data.gd` con 4 campos nuevos:

```gdscript
@export var is_temporary: bool = false
@export var effect_type: StringName = &""   # identificador del efecto
@export var duration: float = -1.0          # -1 = toda la run, >0 = segundos
@export var magnitude: float = 1.0         # multiplicador del efecto
```

Los campos existentes (`id`, `cost_scrap`, `icon`, `stat_modifier_dict`) se preservan sin cambios para compatibilidad con M23 (Workshop).

### Power-Ups iniciales (5 recursos `.tres`)

| Archivo | `effect_type` | `duration` | `magnitude` | Efecto |
|---------|--------------|------------|-------------|--------|
| `pu-rapid-fire.tres` | `pu_rapid_fire` | 10.0 | 1.5 | fire_rate × 1.5 |
| `pu-speed-boost.tres` | `pu_speed_boost` | 8.0 | 1.3 | velocidad × 1.3 |
| `pu-shield-pulse.tres` | `pu_shield_pulse` | -1.0 | 1.0 | bloquea 1 impacto (toda la run) |
| `pu-scrap-magnet.tres` | `pu_scrap_magnet` | 15.0 | 3.0 | radio recolección × 3 (stub M20) |
| `pu-wave-amp.tres` | `pu_wave_amp` | 12.0 | 1.0 | Wave Cannon nivel mínimo = 1 |

Todos tienen `is_temporary = true` y `cost_scrap = 0`.

---

## 2. Drop System

### `scripts/gameplay/loot_table.gd`

Stub con pool fijo. Interfaz estable para que M21/M22 inyecten pesos por heat level sin modificar `EnemyBase`.

```gdscript
# Interfaz pública
static func try_drop(position: Vector2, parent: Node) -> void
```

- `randf() > DROP_CHANCE (0.15)` → no drop
- Elige `UpgradeData` aleatoriamente del `POWER_UP_POOL` (array de preloads)
- Instancia `PowerUpPickup.tscn` y lo añade a `parent` en `position`

### `enemy_base.gd` — modificación en `take_damage()`

Al detectar `_current_hp <= 0`, antes de `queue_free()`:

```gdscript
LootTable.try_drop(global_position, get_parent())
```

---

## 3. Escena `PowerUpPickup.tscn`

```
PowerUpPickup (Area2D)
  ├─ Sprite2D          — tint por effect_type (sin textura en M20, ColorRect tintado)
  ├─ CollisionShape2D  — CircleShape2D radio = 16.0
  └─ power_up_pickup.gd
```

**Collision:**
- Layer: ninguna (el pickup no tiene cuerpo físico propio)
- Mask: Layer 1 (`Jugador_Nucleo`) — solo detecta al Player

**Comportamiento (`power_up_pickup.gd`):**
- Se mueve hacia la izquierda a `DRIFT_SPEED = 60.0` px/s en `_physics_process`
- Auto-destruye si `global_position.x < -100.0`
- `body_entered(body)`: si body es Player → `EventBus.power_up_collected.emit(upgrade_data)` → `queue_free()`

---

## 4. Recolección y Efectos

### EventBus — señales nuevas

```gdscript
signal power_up_collected(upgrade: UpgradeData)
signal power_up_expired(upgrade: UpgradeData)
```

### `Player.apply_powerup(data: UpgradeData) -> void`

Método público en `player.gd`. Switch por `data.effect_type`:

| `effect_type` | Acción en Player |
|--------------|-----------------|
| `pu_rapid_fire` | `_fire_rate_multiplier = data.magnitude` |
| `pu_speed_boost` | `normal_speed *= data.magnitude` |
| `pu_shield_pulse` | `_has_shield = true` |
| `pu_wave_amp` | `_wave_amp_active = true` |
| `pu_scrap_magnet` | stub — log print (M20) |

Método complementario `revert_powerup(data: UpgradeData) -> void` revierte cada efecto.

### `RunManager` — gestión de timers

Nuevos campos:
```gdscript
var active_power_ups: Array[UpgradeData] = []
var _power_up_timers: Dictionary = {}  # StringName → SceneTreeTimer
```

Flujo al recibir `power_up_collected`:
1. Busca al Player en el árbol de escena
2. Llama `player.apply_powerup(data)`
3. Añade a `active_power_ups`
4. Si `duration > 0`: crea `SceneTreeTimer`, al timeout llama `_expire_power_up(data)`

`_expire_power_up(data)`: llama `player.revert_powerup(data)`, elimina de `active_power_ups`, emite `power_up_expired`.

---

## 5. HUD — Panel de Power-Ups Activos

Nuevo `HBoxContainer` (`PowerUpPanel`) en `HUD.tscn`. Se puebla dinámicamente:
- `power_up_collected` → añade `VBoxContainer` con `ColorRect` (tint por tipo) + `Label` countdown
- `power_up_expired` → elimina el elemento correspondiente
- Labels se actualizan cada frame con tiempo restante del timer

---

## Decisiones de Diseño

**¿Por qué no usar BulletPoolManager para los pickups?**
Los power-ups son raros (15% drop chance) y de vida larga. El pool está optimizado para proyectiles de alta frecuencia. Instanciación dinámica es correcta aquí.

**¿Por qué `LootTable` como módulo estático y no señal de EventBus?**
`EnemyBase` ya emite `enemy_destroyed` vía EventBus. Conectar otro listener al mismo evento para drops crearía acoplamiento implícito y orden de ejecución no determinista. El call directo desde `take_damage()` es explícito y trazable.

**¿Por qué `revert_powerup` en Player y no en RunManager?**
Player es el dueño de sus stats. RunManager solo coordina el timing. Separación de responsabilidades.

---

## Criterios de Aceptación

- [ ] Enemigos dropean power-ups con 15% de probabilidad al morir
- [ ] Player auto-colecta al contacto (sin input requerido)
- [ ] Efectos visibles: fire rate, velocidad, escudo (bloquea 1 impacto)
- [ ] `pu_shield_pulse` bloquea exactamente 1 hit y se consume
- [ ] Timers expiran correctamente y revierten efectos
- [ ] HUD muestra power-ups activos con countdown
- [ ] Sin regresiones en colisiones existentes
- [ ] `LootTable` stub preparado para pesos por heat (M21/M22)
