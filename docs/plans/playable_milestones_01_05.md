# Valkyrie-VII — Playable Milestones 1–5

**Estado:** APROBADO
**Versión:** 1.0 — Roadmap Ligero
**Fecha:** 2026-03-15

---

## Context

Bootstrap técnico completo. `BulletPoolManager` autoload registrado (stub), 5 clases Resource en `scripts/data/`, `scenes/main/Main.tscn` vacío, todas las carpetas canónicas creadas. Cero código de gameplay todavía.

Este roadmap define 5 hitos jugables en orden ascendente de complejidad. Cada hito produce algo que puedes ejecutar en Godot e interactuar en la misma sesión en que lo construyes. **La prueba visible manda sobre la perfección técnica.**

Ningún sistema de gameplay se implementa fuera de un hito aprobado.

---

## Milestone 1 — Nave visible + movimiento + modo precisión + límites

### Objetivo jugable
La nave aparece en pantalla y responde al input. Moverse se siente bien: fluido, inmediato, con el freno de precisión ya perceptible. Los bordes detienen la nave limpiamente.

### Archivos probables
| Archivo | Qué hace |
|---------|----------|
| `scenes/entities/Player.tscn` | CharacterBody2D + Sprite2D placeholder + CollisionShape2D (4×4 px) |
| `scenes/entities/player.gd` | Movimiento 8 dir, SPEED=280 / PRECISION=140, clamp a viewport |
| `scenes/main/Main.tscn` | ← instanciar Player.tscn |

### Dependencias mínimas reales
- Input Map: `move_left`, `move_right`, `move_up`, `move_down`, `move_slow` definidos en Project Settings
- `Main.tscn` existe (confirmado)

### Fuera de scope
Disparo, balas, salud, HUD, EventBus, audio, dash, colisión con enemigos, cualquier sistema que no sea mover la nave y que no salga de pantalla.

### Prueba visible obligatoria
F5 → nave aparece → WASD la mueve en 8 direcciones → Shift la frena visiblemente → la nave para en cada borde sin salir. Output limpio.

### Criterios de aceptación
- [ ] Nave visible en pantalla al arrancar
- [ ] Movimiento en las 8 direcciones
- [ ] Modo precisión (hold) produce velocidad visiblemente menor
- [ ] Nave no sale por ningún borde
- [ ] Cero errores en Output al cargar la escena

### Riesgos
| Riesgo | Mitigación |
|--------|-----------|
| `move_and_slide(velocity)` con argumento — crash en Godot 4.4 | `velocity` es propiedad; llamar sin argumentos |
| Scope creep: añadir disparo "ya que estoy" | Rechazar cualquier diff que contenga lógica de balas |

---

## Milestone 2 — Disparo básico + bala + dummy destruible

### Objetivo jugable
Mantener el botón de fuego produce un stream de balas que viajan a la derecha. Hay un dummy (ColorRect rojo) en pantalla. Las balas lo alcanzan y él desaparece al recibir suficientes impactos. El jugador ya tiene un objetivo y puede destruirlo.

### Archivos probables
| Archivo | Qué hace |
|---------|----------|
| `scenes/entities/Bullet.tscn` | Area2D + Sprite2D (8×4 px) + CollisionShape2D (Layer 2) |
| `scenes/entities/bullet.gd` | `initialize(pos, dir)`, `_physics_process` (mover + auto-desactivar al salir de pantalla) |
| `scenes/entities/DummyTarget.tscn` | Area2D + ColorRect + CollisionShape2D (Layer 3). HP=3, muere al llegar a 0. |
| `resources/weapons/weapon-vulcan.tres` | WeaponStats: fire_rate=12, damage=1, projectile_speed=600 |
| `autoloads/bullet_pool_manager.gd` | Implementar `get_bullet()` y `return_bullet()` reales |
| `scenes/entities/player.gd` | + lógica de disparo usando BulletPoolManager |
| `scenes/main/Main.tscn` | + DummyTarget instanciado |

### Dependencias mínimas reales
- M1 completo
- Input Map: acción `fire` definida
- `Bullet.gd` con `class_name Bullet` debe existir antes de tipar el pool

### Fuera de scope
IA enemiga, salud del jugador, Wave Cannon, EventBus, HUD, audio, spread de balas, optimización de bajo nivel. El pool debe funcionar pero su tamaño exacto y métricas de memoria son validación secundaria, no condición de aprobación del hito.

### Prueba visible obligatoria
Hold fire → stream de balas → balas alcanzan el dummy → dummy desaparece después de 3 impactos. Balas desaparecen en el borde derecho si no dan al dummy. Output limpio.

### Criterios de aceptación
- [ ] Balas salen del morro de la nave al mantener fire
- [ ] Balas se mueven en línea recta hacia la derecha
- [ ] Dummy visible y distinguible (ColorRect rojo)
- [ ] Dummy destruido tras recibir suficientes impactos
- [ ] Balas desaparecen al salir de pantalla (no se acumulan)
- [ ] No se usan `add_child()` / `queue_free()` para balas en runtime

### Riesgos
| Riesgo | Mitigación |
|--------|-----------|
| BulletPoolManager._ready() no completo cuando Player intenta get_bullet() | Primer disparo en `_process()`, no en `_ready()` |
| Balas no retornan al pool → acumulación silenciosa | Verificar con Remote Scene Tree que el conteo de Bullet no crece indefinidamente |

---

## Milestone 3 — Primer enemigo funcional (Zángano)

### Objetivo jugable
Un Zángano entra desde la derecha, se mueve hacia la izquierda. El jugador le dispara. El enemigo recibe daño y muere. El primer loop completo: amenaza entra → jugador reacciona → amenaza eliminada.

### Archivos probables
| Archivo | Qué hace |
|---------|----------|
| `scenes/entities/EnemyBase.tscn` | CharacterBody2D + Sprite2D placeholder + CollisionShape2D (Layer 3) |
| `scenes/entities/enemy_base.gd` | Movimiento izquierda, HP desde EnemyProfile, `take_damage()`, muere en HP=0 |
| `resources/enemies/enemy-zangano.tres` | EnemyProfile: max_hp=1, point_value=10 |
| `scenes/main/Main.tscn` | + spawner simple (Timer emite Zánganos cada 2s desde x=1950) |
| `scenes/entities/bullet.gd` | + detectar colisión con Layer 3 → `take_damage()` → return al pool |

### Dependencias mínimas reales
- M2 completo (balas funcionales con pool)
- Clase `EnemyProfile` con `max_hp` como `@export` (ya existe en `scripts/data/`)

### Fuera de scope
Enemigo dispara. Jugador recibe daño. Score. HUD. EventBus. LevelManager. Múltiples tipos de enemigos.

**Notas técnicas (recomendadas, no bloqueantes):**
- Hit flash de 0.05s en impacto mejora significativamente el feel — implementar si el tiempo lo permite
- Estructura FSM mínima (enum State) facilita M4 — recomendada pero no rechaza el hito si la lógica es inline y limpia

### Prueba visible obligatoria
Run → Zánganos entran desde la derecha → hold fire → Zánganos reciben impacto y desaparecen tras 1 bala. Nuevos Zánganos siguen apareciendo. Output limpio.

### Criterios de aceptación
- [ ] Zángano aparece y se mueve en pantalla
- [ ] HP leído de `enemy-zangano.tres` (no hardcodeado)
- [ ] Zángano muere tras `max_hp` impactos
- [ ] Bala desaparece al impactar (retorna al pool)
- [ ] Cero errores en Output

### Riesgos
| Riesgo | Mitigación |
|--------|-----------|
| EnemyProfile.max_hp=0 por defecto → enemigo muere al spawn | Print `profile.max_hp` en `_ready()`, verificar en Output |
| Bala no detecta colisión con Layer 3 → enemigo invulnerable | Revisar collision_layer=3 y collision_mask=2 en inspector del enemigo |

---

## Milestone 4 — Primer intercambio de combate real (peligro para el jugador)

### Objetivo jugable
Los Zánganos disparan de vuelta. Una bala lenta y naranja sale del enemigo hacia el jugador. La hitbox del jugador es de 4×4 px — si te alcanza, moriste. Pantalla en rojo, texto "DESTROYED — Press R". R reinicia. El jugador ya tiene algo que perder.

### Archivos probables
| Archivo | Qué hace |
|---------|----------|
| `autoloads/event_bus.gd` | Señales mínimas: `player_health_changed`, `player_died` |
| `scenes/entities/EnemyBullet.tscn` | Area2D + Sprite2D (naranja) + CollisionShape2D (Layer 4 / mask 1) |
| `scenes/entities/enemy_bullet.gd` | Igual que bullet.gd pero Layer 4. Al tocar Layer 1: daña jugador. |
| `scenes/entities/player.gd` | + HP, `take_damage()`, `_die()` (ocultar nave, overlay rojo, label "DESTROYED") |
| `scenes/entities/enemy_base.gd` | + disparo: Timer cada 1.5s → `BulletPoolManager.get_enemy_bullet()` |
| `autoloads/bullet_pool_manager.gd` | + pool de enemy bullets |
| `project.godot` | + EventBus registrado como autoload |

### Por qué entra EventBus aquí
Cuando Player se destruye, cualquier referencia directa desde Main se invalida. EventBus desacopla la muerte del jugador del sistema que gestiona el reinicio — sin crash cuando el nodo Player desaparece.

### Dependencias mínimas reales
- M3 completo
- EventBus creado ANTES de modificar `player.gd` para emitir señales

### Fuera de scope
RunManager, SaveManager, respawn automático, HUD de salud, score, LevelManager, audio, Wave Cannon, Force module. Muerte = R = `reload_current_scene()`. Simple.

### Prueba visible obligatoria
**Test A:** No moverse → balas enemigas alcanzan al jugador → HP baja → a 0 HP: overlay rojo + "DESTROYED" → R reinicia limpiamente. Sin crash.
**Test B:** Disparar contra el propio stream → HP del jugador no baja. Bala enemiga no daña a otro Zángano.

### Criterios de aceptación
- [ ] Zángano dispara balas que se mueven hacia el jugador
- [ ] Bala enemiga usa BulletPoolManager (no add_child)
- [ ] Jugador tiene HP y toma daño al recibir impacto
- [ ] Jugador muere a 0 HP sin crash
- [ ] `EventBus.player_died` se emite
- [ ] Overlay rojo + texto "DESTROYED" aparece en muerte
- [ ] R reinicia la escena
- [ ] Balas aliadas no dañan al jugador
- [ ] Balas enemigas no dañan a otros enemigos

### Riesgos
| Riesgo | Mitigación |
|--------|-----------|
| Layers mal configurados → friendly fire silencioso o inmunidad | Verificar collision_layer y mask de cada entidad vía Remote Scene Tree |
| Player destruido → null reference crash en otros sistemas | Output debe estar limpio 1-2s después de player_died |

---

## Milestone 5 — Micro vertical slice (30–60 segundos)

### Objetivo jugable
Un encuentro guionizado de ~45 segundos con tres fases de densidad creciente. Un label en pantalla cuenta el tiempo. Sobrevivir: "RUN COMPLETE." Morir: R reinicia desde 0. El jugador siente que el juego tiene forma — un principio, un pico, un desenlace.

### Archivos probables
| Archivo | Qué hace |
|---------|----------|
| `scripts/gameplay/encounter_director.gd` | Node con `_process()` — drive 3 fases de spawn por elapsed time |
| `scenes/ui/HUD.tscn` | CanvasLayer mínimo con Label de timer. `PROCESS_MODE_ALWAYS`. |
| `scenes/ui/hud.gd` | Solo actualiza el label del timer |
| `scenes/main/Main.tscn` | + HUD instanciado + encounter_director como hijo |

**RunManager y score:** opcionales. Si complican el hito, el timer label es suficiente para M5. Añadir solo si el tiempo lo permite y no bloquean la prueba visible.

### Fases del encuentro
| Fase | Tiempo | Spawn |
|------|--------|-------|
| Fase 1 | 0–15s | 1 Zángano cada 1.8s desde x=1950, y aleatorio [200–880] |
| Fase 2 | 15–30s | + 1 Zángano cada 2.2s desde (960, -60) en diagonal. Fase 1 continúa. |
| Fase 3 | 30–45s | 3 Zánganos desde arriba-derecha + 3 desde abajo-derecha cada 2.5s. Fases 1 y 2 paran. |
| Fin | 45s | Label → "RUN COMPLETE", spawners se detienen. |

### Dependencias mínimas reales
- M4 completo (jugador puede morir, R reinicia, EventBus existe)

### Fuera de scope
LevelManager / chunk procedural. SaveManager. Scroll del mundo (EnvironmentManager). Audio. Wave Cannon. Force module. HitStop. Screen shake. Múltiples tipos de enemigos. Score (opcional, no obligatorio). HUD completa.

### Prueba visible obligatoria
**Pass 1:** Jugar normalmente → 3 fases se suceden → a los 45s "RUN COMPLETE" aparece. Sin crash.
**Pass 2:** Morir pronto → Remote Scene Tree muestra cero Zánganos activos ni balas huérfanas. Output limpio post-muerte.
**Pass 3:** Durante Fase 3 (densidad máxima): FPS ≥55 en Godot Profiler.

### Criterios de aceptación
- [ ] Encuentro tiene 3 fases visiblemente distintas por densidad
- [ ] Timer label actualiza en tiempo real
- [ ] "RUN COMPLETE" aparece al sobrevivir 45s
- [ ] R reinicia el encuentro desde 0
- [ ] Muerte no provoca crash; entidades se limpian
- [ ] ≥55 FPS durante Fase 3
- [ ] Cero errores en Output durante un run limpio completo
- [ ] Al menos 3 de 5 intentos son superables (dificultad calibrada)

### Riesgos
| Riesgo | Mitigación |
|--------|-----------|
| Fase 3 imposible de superar | Desarrollador debe completar un run antes de enviarlo a QA |
| Muerte no limpia entidades activas → errores en siguiente run | Remote Scene Tree post-muerte es prueba obligatoria (Pass 2) |
| Scope creep: añadir score, shop, wave cannon "ya que estoy" | Lead rechaza cualquier sistema no listado aquí en el diff |

---

## Grafo de dependencias

```
M1 (nave + movimiento)
 └── M2 (disparo + bala + dummy destruible)
      └── M3 (enemigo funcional: mueve, recibe daño, muere)
           └── M4 (enemigo dispara + jugador muere + R reinicia)
                └── M5 (encuentro 3 fases + timer + RUN COMPLETE)
```

Estrictamente secuencial. Cada hito es jugable y testeable de forma independiente.

---

## Evolución de sistemas por hito

| Sistema | M1 | M2 | M3 | M4 | M5 |
|---------|----|----|----|----|-----|
| BulletPoolManager | Stub | Implementado | Sin cambio | + pool enemy bullets | Sin cambio |
| EventBus | No | No | No | Creado (2 señales) | Sin cambio |
| Player | Movimiento | + disparo | Sin cambio | + HP + muerte | Sin cambio |
| Enemy | No | No | ENTER + DEAD | + ATTACK | Sin cambio |
| HUD | No | No | No | No | Timer label |
| RunManager | No | No | No | No | Opcional |
| WeaponStats .tres | No | Creado | Sin cambio | Sin cambio | Sin cambio |
| EnemyProfile .tres | No | No | Creado | + projectile_pattern | Sin cambio |

---

## Contratos irrevocables (todos los hitos)

- Cero `add_child()` / `queue_free()` para balas en runtime
- GDScript con tipado estricto en todo archivo nuevo
- Collision layers solo en inspector, nunca por código en runtime
- Prueba visible obligatoria antes de aprobar cada hito

---

## Verificación final (tras M5)

F5 → nave aparece → dispara → Zánganos entran → mueren → disparan de vuelta → jugador puede morir → R reinicia → 3 fases en ~45s → "RUN COMPLETE". FPS estable. Output limpio. Sin crashes.

---

*Documento generado con input de tres agentes especializados: gameplay feel, arquitectura Godot 2D, y QA/criterios de aceptación.*
