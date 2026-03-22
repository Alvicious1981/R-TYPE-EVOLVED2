# Hito 01 — Player Ship: Movement + Precision Mode + Screen Bounds

**Estado:** ACEPTADO
**Fecha:** 2026-03-15
**Auditado:** 2026-03-17
**Referencia:** docs/plans/playable_milestones_01_05.md — Milestone 1

---

## Objetivo

Nave visible en pantalla. Movimiento 8 direcciones. Modo precisión al mantener `move_slow`. Nave limitada al área visible. Sin disparo, sin enemigos, sin HUD.

---

## Archivos a crear

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `scenes/entities/player.gd` | Script | `class_name Player extends CharacterBody2D`. Movimiento, clamp. |
| `scenes/entities/Player.tscn` | Escena | CharacterBody2D + Polygon2D (placeholder) + CollisionShape2D (4×4 px) + HitboxDebug (opcional, oculto). |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `scenes/main/Main.tscn` | Instanciar Player.tscn en Vector2(192, 540) |
| `project.godot` | Añadir `[input]` (5 acciones) + `[layer_names]` (6 capas) |

---

## Decisiones de implementación

- `move_and_slide()` sin argumentos (Godot 4.4+ API — `velocity` es propiedad)
- Clamping manual de posición al viewport (`_clamp_to_viewport()`) — no se usan colisiones de bordes
- `collision_layer = 1` (Jugador_Nucleo), `collision_mask = 0` en M1 (sin objetos que colisionar)
- Placeholder: Polygon2D triángulo blanco/azul apuntando a la derecha — sin assets externos
- HitboxDebug: segundo Polygon2D 4×4 px rojo, `visible = false` por defecto, toggle via `@export`
- No EventBus, no WeaponStats, no BulletPoolManager modificado

---

## Precondiciones que se configuran en este hito

- Input Map: `move_left` (A), `move_right` (D), `move_up` (W), `move_down` (S), `move_slow` (Shift)
- Collision layers: Jugador_Nucleo=1, Municion_Aliada=2, Chasis_Hostil=3, Municion_Biomecanica=4, Modulo_Tactico_Force=5, Terreno_Solido=6

---

## Prueba visible

F5 → nave aparece → WASD la mueve en 8 dir → Shift la frena → no sale por ningún borde → Output limpio.

---

## Fuera de scope

Disparo, balas, salud, HUD, EventBus, audio, dash, enemies, WeaponStats.
