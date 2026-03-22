# Hito 02 — Player Fire: Disparo + Bala + Dummy Destruible

**Estado:** EN EJECUCIÓN
**Fecha:** 2026-03-15
**Referencia:** docs/plans/playable_milestones_01_05.md — Milestone 2

---

## Objetivo

El jugador puede disparar manteniendo `fire`. Las balas viajan hacia la derecha y desaparecen al salir de pantalla o impactar. Un dummy destruible (ColorRect rojo) recibe daño y desaparece a 0 HP. Sin enemigos reales, sin HUD, sin EventBus.

---

## Archivos a CREAR

| Ruta | Descripción |
|------|-------------|
| `scenes/entities/bullet.gd` | `class_name Bullet extends Area2D`. `initialize`, `deactivate`, `_physics_process`, `_on_area_entered`. |
| `scenes/entities/Bullet.tscn` | Area2D root + Polygon2D placeholder + CollisionShape2D. `collision_layer=2, collision_mask=4` |
| `scenes/entities/dummy_target.gd` | `class_name DummyTarget extends Area2D`. HP=3, `take_damage(amount)`, `queue_free()` a 0 HP. |
| `scenes/entities/DummyTarget.tscn` | Area2D root + ColorRect (48x48 rojo) + CollisionShape2D. `collision_layer=4, collision_mask=0` |
| `resources/weapons/weapon-vulcan.tres` | WeaponStats: fire_rate=12.0, damage=1, spread_angle=0.0, projectile_speed=600.0 |

---

## Archivos a MODIFICAR

| Ruta | Cambio |
|------|--------|
| `autoloads/bullet_pool_manager.gd` | Pool completo: preload Bullet.tscn, _ready() pre-alloca, get_bullet(), return_bullet(). Array[Node] a Array[Bullet]. |
| `scenes/entities/player.gd` | Renombrar _delta a delta. Añadir weapon: WeaponStats, _fire_timer, _handle_fire(delta), _shoot(). |
| `scenes/main/Main.tscn` | Añadir DummyTarget instanciado en Vector2(1500, 540). |
| `project.godot` | Añadir acción fire (Space=32, Z=90) al [input]. |

---

## Bitmask critico (Layer N != bitmask N en Godot 4)

| Layer nombre | Layer numero | Decimal bitmask |
|---|---|---|
| Municion_Aliada | 2 | 2 |
| Chasis_Hostil | 3 | 4 |

Bullet.tscn: collision_layer = 2, collision_mask = 4
DummyTarget.tscn: collision_layer = 4, collision_mask = 0

---

## Decisiones clave

1. bullet.gd usa set_deferred("monitoring", ...) para cambios de colision dentro de callbacks de fisica.
2. _physics_process en bullet se salta si not visible.
3. Return to pool desde _on_area_entered Y desde _physics_process al salir de pantalla (x > 1960).
4. BulletPoolManager.get_bullet(pos, dir, speed, damage) con 4 parametros.
5. @export var weapon: WeaponStats = preload("res://resources/weapons/weapon-vulcan.tres") en player.gd.
6. Muzzle offset: Vector2(18.0, 0.0) — nariz del triangulo ShipPolygon.

---

## Orden de implementacion

1. resources/weapons/weapon-vulcan.tres
2. scenes/entities/bullet.gd — class_name Bullet necesaria antes del pool
3. scenes/entities/Bullet.tscn
4. autoloads/bullet_pool_manager.gd — usa Array[Bullet] y preload
5. scenes/entities/dummy_target.gd
6. scenes/entities/DummyTarget.tscn
7. scenes/entities/player.gd — modificar con disparo
8. scenes/main/Main.tscn — anadir DummyTarget
9. project.godot — anadir fire action

---

## Restricciones

CERO add_child() / queue_free() para balas en runtime.
NO EventBus, NO HUD, NO score, NO audio, NO Wave Cannon, NO enemigo real.

---

## Prueba visible

F5 - nave visible - mantener Space o Z - stream de balas a la derecha - balas impactan dummy rojo en x=1500 - dummy desaparece tras 3 impactos - balas desaparecen al salir de pantalla - Output limpio.
