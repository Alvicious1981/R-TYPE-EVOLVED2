# Valkyrie-VII — Post-M5 Stabilization & Phase 2 Roadmap

**Estado:** APROBADO
**Fecha:** 2026-03-17
**Versión:** 1.0

---

## Context

Hitos M1–M5 están implementados y el vertical slice de 45s es funcional. El juego tiene nave, disparo, enemigos, muerte del jugador, HUD con timer y EncounterDirector con 3 fases. La muerte del jugador se detecta mediante polling (`player.is_dead`) — no mediante EventBus. **EventBus no existe en el código actual** (cero referencias en ningún `.gd`). Antes de abrir la siguiente fase de desarrollo, hay que consolidar el estado actual: reconciliar lo que el plan decía con lo que hay en código, eliminar ruido técnico no bloqueante, y definir un roadmap de hitos pequeños y motivadores que construyan sobre el vertical slice sin desbordarse.

---

## BLOQUE A — Estabilización post-M5

### A1. Reconciliación plan ↔ comportamiento real

Diferencias verificadas entre el plan M1–M5 y el estado real del código:

| Ítem | Plan decía | Estado real | Acción |
|------|-----------|-------------|--------|
| EventBus autoload | Registrado en project.godot en M4 | **No existe** — cero referencias en ningún `.gd`; muerte se detecta con `player.is_dead` en polling | **Nada que hacer en Bloque A.** EventBus entra en M7 cuando haya múltiples sistemas que necesiten comunicarse. |
| Hit flash | "Recomendado" en M3 | No implementado | **Posponer a M7** — documentado como deuda |
| FSM enum en enemy_base | "Recomendada" en M3 | Desconocido — puede ser inline | **Verificar**: no es bloqueante; documentar si es inline |
| `player.is_dead` | Seteado en `_die()` en M4 | Declarado en `player.gd:9`, comprobado en `encounter_director.gd:31` | **Verificar** que `_die()` lo setea correctamente con ejecución real (Pass 2 del Clean Floor Protocol) |
| RunManager | "Opcional" en M5 | No implementado | **Posponer a M6** — es el primer hito de Bloque B |

### A2. Warnings no bloqueantes — qué se corrige y qué se pospone

#### Se corrige en Bloque A

| Warning / Issue | Archivo | Fix |
|----------------|---------|-----|
| **Nested project warning** — `r-type-2/` contiene `project.godot` propio | `r-type-2/` | Añadir `r-type-2/.gdignore` (archivo vacío) para que Godot ignore la subcarpeta como proyecto |
| **Nested project warning** — `valkyrie-vii-(4.4)/` idem | `valkyrie-vii-(4.4)/` | Añadir `valkyrie-vii-(4.4)/.gdignore` |
| **Null safety** — `return_bullet(bullet)` y `return_enemy_bullet(bullet)` sin guard | `autoloads/bullet_pool_manager.gd` | Añadir guardia: `if bullet == null: return` al inicio de cada función |
| **Archivo huérfano** — `scenes/main/spawner.gd` no está en ninguna escena | `scenes/main/spawner.gd` | Eliminar (está en git; recuperable si se necesita) |
| ~~EventBus~~ | — | **No aplicable**: EventBus no existe y el código actual no lo necesita. Se introduce en M7. |

#### Se pospone (deuda documentada, no bloqueante)

| Deuda | Razón para posponer |
|-------|-------------------|
| `screen_size` hardcoded en `player.gd` | Funciona correctamente en 1920×1080; cambia con resolución dinámica (futura feature) |
| Sin null-check en `_ENEMY_SCENE.instantiate()` en `encounter_director.gd` | Falla solo si el .tscn no existe — no ocurre en condiciones normales |
| Hit flash shader en enemigos | Feature de feel; va en M7 del Bloque B |
| FSM enum en `enemy_base.gd` si es inline | Funcional aunque sea inline; refactor natural cuando llegue el segundo tipo de enemigo |
| Anchors/size warnings en Control de HUD | Inspeccionar en editor; si no producen comportamiento roto, posponer al hito HUD completo |

### A3. Clean Floor Protocol final

Antes de abrir M6, ejecutar:
- [ ] F5 → run completo 45s sin errores en Output
- [ ] Remote Scene Tree post-muerte: 0 EnemyBase, 0 EnemyBullet activos
- [ ] Verificar que nested project warnings han desaparecido en la consola del editor
- [ ] Confirmar que el único autoload es BulletPoolManager (EventBus entra en M7)

### Archivos críticos del Bloque A

| Archivo | Acción |
|---------|--------|
| `autoloads/bullet_pool_manager.gd` | Añadir null guard en `return_bullet` y `return_enemy_bullet` |
| `scenes/main/spawner.gd` | Eliminar |
| `r-type-2/.gdignore` | Crear (vacío) |
| `valkyrie-vii-(4.4)/.gdignore` | Crear (vacío) |

---

## BLOQUE B — Próxima fase jugable (Hitos 6–10)

> **Ningún hito de este bloque se implementa hasta completar y aprobar el Bloque A.**

### Principios de diseño para esta fase

- Cada hito es jugable y testeable el mismo día que se construye.
- No abrir más de un sistema nuevo por hito.
- No implementar Force module, shop, guardado, roguelite ni backend todavía.
- La prueba visible manda sobre la perfección técnica.

---

### Hito 6 — Score de sesión visible

**Objetivo jugable:** Los Zánganos valen puntos. El número sube en pantalla al destruirlos. El jugador tiene una razón para jugar mejor, no solo sobrevivir.

**Implementación mínima (sin EventBus):**
- `autoloads/run_manager.gd` — Autoload ligero con `current_score: int` y `func add_score(value: int) -> void`
- `enemy_base.gd` llama `RunManager.add_score(profile.point_value)` directamente en `_die()`
- HUD label de score añadido a `HUD.tscn` / `hud.gd` — lee `RunManager.current_score` cada frame (o con señal local)
- `run_manager.gd` resetea `current_score = 0` al reiniciar la escena

**Fuera de scope:** EventBus, multiplicador, combo, chatarra, guardado, pantalla de resultados.

**Nota arquitectónica:** La llamada directa `RunManager.add_score()` es válida porque RunManager es Autoload singleton — no crea acoplamiento problemático. EventBus se añade en M7 cuando haya múltiples receptores para la misma señal.

**Prueba visible:** Matar Zángano → score sube en HUD. R reinicia → score vuelve a 0.

---

### Hito 7 — Hit flash + segundo enemigo (Torreta Estática) + EventBus

**Objetivo jugable:** Los impactos se sienten. Hay un nuevo tipo de amenaza que no se mueve pero dispara en abanico. Aprender a limpiarla con fuego sostenido ya vale más que esquivarla.

**Sistemas nuevos:**
- `assets/shaders/hit_flash.gdshader` — shader de hit flash (uniform bool). Activado con Tween 0.05s en `take_damage()`.
- `autoloads/event_bus.gd` — señales mínimas: `enemy_destroyed(score_value: int, position: Vector2)`. Registrado en project.godot. RunManager migra a escuchar esta señal en lugar de llamada directa.
- `resources/enemies/enemy-torreta.tres` — EnemyProfile: `max_hp=3`, `point_value=30`
- EncounterDirector actualizado para spawnear Torretas en Fase 2 (posición fija en borde derecho)
- Torreta no tiene movimiento (`move_dir = Vector2.ZERO`); dispara burst de 3 balas cada 2s en abanico ±15°

**Por qué entra EventBus aquí:** Con dos tipos de enemigos emitiendo `enemy_destroyed`, múltiples sistemas (RunManager, futuros efectos de partículas) necesitan reaccionar. La llamada directa a RunManager se vuelve frágil. Es el momento justo — ni antes ni después.

**Fuera de scope:** Torreta adherida a geometría, múltiples ángulos de abanico, Wave Cannon.

**Prueba visible:** Torreta aparece en Fase 2 → impactos producen flash blanco → muere a 3 impactos → vale 30 puntos.

---

### Hito 8 — Pacing de encuentro mejorado

**Objetivo jugable:** El encuentro de 45s respira. Hay un momento de calma antes de la Fase 3. La densidad sube de forma más legible y el jugador siente que puede aprender el patrón.

**Sistemas nuevos:**
- EncounterDirector añade "Fase de transición" (2s de spawn pausado entre fases)
- Fase 2 mezcla Zánganos + Torretas con lógica de alternancia
- Fase 3 sube a formaciones de 2 Zánganos simultáneos desde esquinas opuestas

**Fuera de scope:** LevelManager, chunks, scroll del mundo.

**Prueba visible:** 3 fases son visiblemente distintas por densidad y tipo. El jugador puede anticipar el escalado.

---

### Hito 9 — Primer miniboss (Explorador Dreadnought, 2 fases)

**Objetivo jugable:** A los 45s, en lugar de "RUN COMPLETE", entra una nave grande. Tiene 15 HP y 2 patrones de ataque. Destruirlo es el nuevo objetivo. Es el primer pico de tensión real.

**Sistemas nuevos:**
- `scenes/entities/MiniBoss.tscn` — CharacterBody2D más grande (placeholder ColorRect distinto)
- `scripts/entities/mini_boss.gd` — FSM simple: `ENTER → ATTACK_A → ATTACK_B [HP<50%] → DEAD`
- `resources/enemies/enemy-explorador.tres` — EnemyProfile extendido con `phase2_threshold: float`
- EncounterDirector: tras 45s si jugador vivo → spawn MiniBoss; detener oleadas normales
- Screen flash (CanvasLayer overlay blanco 0.1s) en transición de fase A→B
- "SECTOR CLEARED" en HUD al morir el MiniBoss

**Fuera de scope:** Full Dreadnought (fases 3-4, armazón destructible), múltiples minibosses.

**Prueba visible:** Sobrevivir 45s → MiniBoss entra → a 50% HP cambia patrón (flash visible) → muere → "SECTOR CLEARED". R reinicia desde 0.

---

### Hito 10 — Polish básico A/V

**Objetivo jugable:** La destrucción se siente. Morir impacta visualmente. El juego ya no parece un prototipo en movimiento.

**Sistemas nuevos:**
- `CameraShake` component (según TDD §9.3) — trauma en muerte de enemigo (0.1), trauma en muerte de MiniBoss (0.4)
- Explosión de muerte: `CPUParticles2D` pre-colocada en enemy_base (3-5 partículas cuadradas)
- 2-3 SFX placeholder (beeps sintéticos) para disparo, muerte de enemigo, muerte de jugador — `AudioStreamPlayer` en escena (no AudioManager completo)

**Fuera de scope:** AudioManager completo, música FM, grazing glow, Wave Cannon, Force module.

**Prueba visible:** Matar enemigo → partículas aparecen + leve shake. Recibir impacto letal → shake + fade rojo. Juego sigue a ≥55 FPS.

---

## Grafo de dependencias (Bloque B)

```
[M5 completado]
 └── Bloque A (estabilización)
      └── M6 (score de sesión visible — sin EventBus)
           └── M7 (hit flash + torreta + EventBus)
                └── M8 (pacing mejorado)
                     └── M9 (miniboss)
                          └── M10 (polish A/V)
```

---

## Lista de deudas técnicas no bloqueantes (backlog)

| Deuda | Origen | Estado |
|-------|--------|--------|
| `screen_size` hardcoded en player.gd | M1 | Posponer — corregir antes de multi-resolución |
| FSM enum formal en enemy_base.gd | M3 | Posponer — refactorizar en M7 con segundo tipo |
| Anchors/size warnings en Control de HUD | M5 | Posponer — revisar en hito HUD completo |
| Hit flash recomendado en M3 | M3 | Cubierto en M7 |
| EventBus (no existe aún) | M4 (plan no ejecutado) | Introducido en M7 cuando haya ≥2 sistemas receptores |
| RunManager básico | M5 (opcional) | Cubierto en M6; scrap/chatarra pospuesto |
| AudioManager pool completo | TDD §7.2 | Posponer a después de M10 |
| Wave Cannon | PRD §4.3 | Posponer a después de M10 |
| Force Module | PRD §4.4 | Posponer indefinidamente (post-miniboss) |
| SaveManager / guardado persistente | TDD §8.2 | Posponer a versión con runs completas |
| LevelManager / chunks procedurales | TDD §4 | Posponer a después de Force module |

---

## Verificación end-to-end (post Bloque A, antes de abrir M6)

1. Abrir Godot → 0 warnings de nested project en consola del editor
2. F5 → run de 45s completo → Output sin errores rojos
3. Remote Scene Tree post-muerte: 0 instancias activas de Bullet/EnemyBullet/EnemyBase
4. Project Settings → Autoloads: solo BulletPoolManager registrado (EventBus entra en M7)
5. `scenes/main/spawner.gd` no aparece en el explorador de archivos del proyecto
