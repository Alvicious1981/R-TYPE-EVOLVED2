# Hito 05 — Micro Vertical Slice (45s Encounter)

**Fecha:** 2026-03-17
**Agentes:** Planner → Worker → Validator
**Estado:** IMPLEMENTACIÓN COMPLETA — pendiente verificación Validator

---

## Resumen del Estado Real (auditado 2026-03-17)

El Hito 05 estaba implementado en un 95% antes de este ciclo de swarm.
El Worker completó el 5% restante: corrección del bug Y-axis en `enemy_bullet.gd`.

### Componentes DONE (pre-existentes)

| Componente | Archivo | Estado |
|-----------|---------|--------|
| Starfield scroll | `scenes/main/background.gd` | DONE |
| Encounter Director 3 fases | `scripts/gameplay/encounter_director.gd` | DONE |
| HUD timer + victory label | `scenes/ui/hud.gd` + `HUD.tscn` | DONE |
| Player.is_dead público | `scenes/entities/player.gd` | DONE |
| EnemyBase.move_dir export | `scenes/entities/enemy_base.gd` | DONE |
| Main.tscn wiring completo | `scenes/main/Main.tscn` | DONE |

### Cambio aplicado por el Worker

| Archivo | Cambio | Razón |
|---------|--------|-------|
| `scenes/entities/enemy_bullet.gd` | Añadir `or global_position.y < -40.0 or global_position.y > 1120.0` en bounds check | Balas diagonales de Fases 2-3 escapaban por Y sin retornar al pool |

---

## Skeleton of Thought

```
Estructura:
  Fondo → Background (starfield 200 estrellas, scroll hacia izq)
  Combate → EncounterDirector (3 fases, 45s total, spawn EnemyBase desde pool)
  HUD → CanvasLayer PROCESS_MODE_ALWAYS (timer countdown + run_complete label)
  Pool → BulletPoolManager (balas aliadas 2000 + enemigas 500)
  Fin → victoria (T=0, "RUN COMPLETE — Press R") o derrota (is_dead, "GAME OVER — Press R")
  Reinicio → R key en ambos estados
```

---

## Arquitectura del Encounter Director

### Fases de la Secuencia (45 segundos totales)

| Fase | Tiempo | Descripción | Spawn |
|------|--------|-------------|-------|
| Fase 1 | 0–15s | Oleada horizontal estable | Cada 1.8s desde x=1980, y aleatorio 100-980 |
| Fase 2 | 15–30s | Oleada desde arriba-centro diagonal | Cada 2.2s desde x=960, y=-60, move_dir diagonal |
| Fase 3 | 30–45s | Oleada final doble densidad | Cada 0.9s alternando desde esquinas derecha |
| Victoria | 45s | Timer llega a 0, jugador vivo | Muestra "RUN COMPLETE — Press R", detiene spawn |
| Derrota | any | player.is_dead == true | Muestra "GAME OVER — Press R", detiene spawn |

### Secuencia de Señales

```
EncounterDirector._ready() → start_encounter()
  → _phase_timer.start(15.0)
  → _spawn_timer.start()
  → _encounter_timer.start(45.0)

_encounter_timer.timeout → emit_signal("run_complete")
  → HUD.show_run_complete()

player.is_dead → EncounterDirector._physics_process detecta
  → emit_signal("run_complete", false) → HUD muestra GAME OVER
```

---

## Estructura de Archivos

### Creados en el ciclo de Hito 05

```
scripts/gameplay/encounter_director.gd   ← Director de encuentro (3 fases)
scenes/ui/hud.gd                         ← HUD (timer + labels fin)
scenes/ui/HUD.tscn                       ← CanvasLayer layer=5
scenes/main/background.gd               ← Starfield scroll
```

### Modificados en el ciclo de Hito 05

```
scenes/entities/player.gd               ← is_dead público, reinicio con R
scenes/entities/enemy_base.gd           ← move_dir export, bounds Y
scenes/entities/enemy_bullet.gd         ← bounds check añade eje Y (Worker M5)
scenes/main/Main.tscn                   ← Background + EncounterDirector + HUD wired
```

---

## El Único Fix del Worker: enemy_bullet.gd

### Problema detectado por el Planner
`_physics_process` de `enemy_bullet.gd` tenía:
```gdscript
if global_position.x < -40.0 or global_position.x > 1960.0:
    BulletPoolManager.return_enemy_bullet(self)
```
Las balas enemigas diagonales de Fases 2 y 3 escapan por Y=-40 o Y>1120 sin retornar al pool → pool leak silencioso en Fase 3 si jugador esquiva.

### Fix aplicado
```gdscript
if global_position.x < -40.0 or global_position.x > 1960.0 \
        or global_position.y < -40.0 or global_position.y > 1120.0:
    BulletPoolManager.return_enemy_bullet(self)
```

---

## Criterios de Aceptación

| # | Criterio | Verificación |
|---|---------|-------------|
| CA-1 | F5 sin errores rojos en Output | Output panel |
| CA-2 | Fondo scrollea horizontalmente | Visual |
| CA-3 | Fase 1: Zánganos horizontales cada ~1.8s (0-15s) | Visual + cronómetro |
| CA-4 | Fase 2: Zánganos desde arriba-centro diagonal (15-30s) | Visual |
| CA-5 | Fase 3: oleadas densas desde esquinas derecha (30-45s) | Visual |
| CA-6 | Timer label countdown actualiza en tiempo real | Visual |
| CA-7 | "RUN COMPLETE — Press R" aparece al llegar a 45s | Visual |
| CA-8 | R en victoria reinicia desde 0 | Input R |
| CA-9 | Muerte detiene spawn; "GAME OVER — Press R"; R reinicia | Visual |
| CA-10 | FPS ≥ 55 en Fase 3 | Godot Profiler |
| CA-11 | Pool enemy bullets no se agota (no push_warning en Output) | Output panel |

---

## Clean Floor Protocol

- [ ] `enemy_bullet.gd` línea ~32: contiene `global_position.y < -40.0`
- [ ] Remote Scene Tree post-muerte: 0 EnemyBase, 0 EnemyBullet activos
- [ ] `DummyTarget` y `spawner.gd` no instanciados en Main.tscn
- [ ] Output limpio durante run completo de 45s
- [ ] Todo GDScript con tipado estricto
- [ ] Ningún archivo out-of-scope modificado

---

## Archivos Out of Scope (NO tocar)

- `autoloads/bullet_pool_manager.gd`
- `scripts/data/`
- `resources/`
- `project.godot`
- `scenes/entities/DummyTarget.tscn`
- `scenes/main/spawner.gd` (huérfano)
