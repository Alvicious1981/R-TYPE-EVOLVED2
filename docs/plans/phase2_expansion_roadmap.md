# Phase 2 Expansion Roadmap — Valkyrie-VII
**Estado:** Planificación aprobada | **Última revisión:** 2026-03-28
**Prerrequisitos cerrados:** M1–M16 (Core Loop completo)

---

## Prerrequisitos Inmediatos (antes de M19)

### M17 — Inyección de Audio Real
- Reemplazar `AudioStreamGenerator` beeps en `scenes/main/sfx_player.gd` con `.wav` reales
- Archivos mínimos: `shoot.wav`, `enemy_death.wav`, `player_death.wav` en `assets/audio/sfx/`
- La arquitectura SfxPlayer ya soporta esto — cambio puntual

### M18 — Force Module
- Implementar `scenes/entities/force.gd` con 3 modos: frontal accouple, rear accouple, autonomous deploy
- Física de rebote via `RayCast2D`, recarga Wave Cannon en impacto (Kinetic Synergy)
- Datos: `resources/force/force-config-default.tres` (usa `ForceConfig` ya en `scripts/data/force_config.gd`)
- Nuevo layer activo: `Modulo_Tactico_Force` (layer 5 — ya definido en Project Settings)

---

## Fase 2 — Hitos de Contenido (M19–M23)

### M19 — Biomas y Arte (Sprite Integration)
**Objetivo:** Reemplazar placeholders ColorRect con sprites reales; definir el primer bioma completo.

**Nuevo sistema — `BiomeProfile` Resource:**
```gdscript
# scripts/data/biome_profile.gd
class_name BiomeProfile extends Resource
@export var biome_id: String = ""
@export var display_name: String = ""
@export var background_texture: Texture2D
@export var parallax_layers: Array[Texture2D] = []
@export var accent_color: Color = Color.WHITE
@export var enemy_pool: Array[EnemyProfile] = []
@export var music_track: AudioStream
```

**Archivos a crear/modificar:**
- `scripts/data/biome_profile.gd` — nueva clase Resource
- `resources/biomes/biome-nebula.tres` — Bioma 1: Nebulosa (paleta cyan/grey)
- `assets/sprites/player/valkyrie-*.png` — sprites para los 5 ships (o placeholders 32×16 px)
- `assets/sprites/enemies/zangano.png`, `torreta.png`, `dreadnought.png`
- `scenes/levels/Background.tscn` ya existe — actualizar para leer `BiomeProfile`

**Criterios de aceptación:**
- [ ] Sprites reales visibles en gameplay (no `ColorRect`)
- [ ] `BiomeProfile` serializable como `.tres`
- [ ] 1 bioma funcional con background, parallax 3-layer, y enemy pool definido
- [ ] Sin regresiones de rendimiento (60 FPS estable)

---

### M20 — Power-Ups In-Run
**Objetivo:** Drops de power-ups temporales durante la run (no el Workshop permanente).

**Arquitectura — Drop System:**
- `UpgradeData` Resource ya existe en `scripts/data/upgrade_data.gd` — ampliar con campos:
  - `is_temporary: bool` — distingue power-up in-run de mejora permanente
  - `effect_type: StringName` — identificador del efecto
  - `duration: float` — -1 = toda la run, >0 = segundos
  - `magnitude: float` — multiplicador del efecto
- `scenes/entities/PowerUpPickup.tscn` — nodo `Area2D` con sprite animado, auto-collect al tocar
- `scripts/gameplay/loot_table.gd` — tabla de drops weighted por heat level
- Integrar drop en `enemy_base.gd` → señal `enemy_destroyed` ya en EventBus

**Power-ups iniciales (5 tipos):**
| ID | Nombre | Efecto |
|----|--------|--------|
| `pu_rapid_fire` | Rapid Fire | fire_rate × 1.5 durante 10s |
| `pu_speed_boost` | Afterburner | velocidad × 1.3 durante 8s |
| `pu_shield_pulse` | Escudo Pulso | bloquea 1 impacto (permanente esta run) |
| `pu_scrap_magnet` | Imán de Chatarra | radio recolección scrap × 3 durante 15s |
| `pu_wave_amp` | Wave Amplifier | Wave Cannon nivel mínimo = 1 durante 12s |

**Archivos a crear/modificar:**
- `scripts/data/upgrade_data.gd` — añadir campos `is_temporary`, `effect_type`, `duration`, `magnitude`
- `resources/upgrades/pu-rapid-fire.tres` (y los 4 restantes)
- `scenes/entities/PowerUpPickup.tscn` + `scripts/entities/power_up_pickup.gd`
- `scripts/gameplay/loot_table.gd` — sistema de drops weighted
- `autoloads/run_manager.gd` — añadir `active_power_ups: Array[UpgradeData]` y timers
- `scenes/ui/HUD.tscn` — panel de power-ups activos (iconos + countdown)

**EventBus — señales nuevas:**
```gdscript
signal power_up_collected(upgrade: UpgradeData)
signal power_up_expired(upgrade: UpgradeData)
```

**Criterios de aceptación:**
- [ ] Enemigos dropean power-ups con probabilidad configurable
- [ ] Player auto-colecta al contacto
- [ ] Efectos visibles (fire rate, velocidad, escudo)
- [ ] HUD muestra power-ups activos con timer countdown
- [ ] `RunManager` serializa power-ups activos (por si hay pausa)

---

### M21 — Nuevos Enemigos
**Objetivo:** Ampliar el catálogo de enemigos de 3 a 6 tipos; integrar en EncounterDirector.

**3 nuevos perfiles:**
| ID | Nombre | HP | Puntos | Comportamiento |
|----|--------|----|--------|----------------|
| `kamikaze` | EnemyKamikaze | 1 | 15 | Rush directo al jugador en línea recta, velocidad 400px/s |
| `shielder` | EnemyShielder | 5 | 50 | Bloquea balas aliadas con escudo frontal; flanqueable por los lados |
| `sprinter` | EnemySprinter | 2 | 25 | Movimiento en zigzag horizontal, dispara ráfagas cortas |

**Archivos a crear:**
- `resources/enemies/enemy-kamikaze.tres`
- `resources/enemies/enemy-shielder.tres`
- `resources/enemies/enemy-sprinter.tres`
- `scenes/entities/EnemyKamikaze.tscn` + `enemy_kamikaze.gd` (FSM: `IDLE → RUSHING`)
- `scenes/entities/EnemyShielder.tscn` + `enemy_shielder.gd` (FSM: `IDLE → SHIELDING → EXPOSED`)
- `scenes/entities/EnemySprinter.tscn` + `enemy_sprinter.gd` (FSM: `ZIGZAG → FIRING`)

**EncounterDirector:**
- Añadir slot Phase 2+ para Shielders y Sprinters (heat level condicional)
- Kamikaze como sub-wave en Phase 3

**Criterios de aceptación:**
- [ ] 3 perfiles `.tres` válidos y cargables con `EnemyProfile`
- [ ] Comportamiento FSM funcional para cada tipo
- [ ] Integración en `encounter_director.gd` sin romper fases existentes
- [ ] Sin regresiones en colisiones (mismo layer `Chasis_Hostil`)

---

### M22 — Generación Procedural de Niveles (Chunk System)
**Objetivo:** Reemplazar el encounter timer de 45s por un sistema de chunks procedurales streaming.

**Arquitectura — ChunkManager:**
```
EncounterDirector (actual) → deprecar timer logic
ChunkManager (nuevo autoload o nodo de Main.tscn)
  ├─ Leer LevelChunk.tres (weighted pool por biome + heat)
  ├─ Instanciar max 3 chunks en memoria (Object Culling Directional)
  ├─ Avanzar según posición X del jugador
  └─ Emitir señal chunk_completed para encadenar siguiente
```

**`LevelChunk` Resource (ampliar el existente en `scripts/data/level_chunk.gd`):**
```gdscript
@export var chunk_type: StringName  # "breathing", "pressure", "franchise", "elite", "transition", "boss"
@export var spawn_waves: Array[Dictionary]  # [{enemy_id, count, formation, delay}]
@export var min_heat: int = 0
@export var max_heat: int = 4
@export var weight: float = 1.0
@export var duration_seconds: float = 15.0
@export var next_chunk_types: Array[StringName] = []  # transiciones permitidas
```

**Chunks iniciales a diseñar (6 archivos `.tres`):**
| Tipo | Nombre | Descripción |
|------|--------|-------------|
| `breathing` | OpenLane | Solo Zánganos espaciados, heat 0–1 |
| `pressure` | CrossFire | Torretas + Zánganos simultáneos, heat 1–3 |
| `franchise` | ElitePatrol | 2 Shielders + 4 Sprinters, heat 2–4 |
| `elite` | KamikazeWave | 6 Kamikazes en V, heat 2–4 |
| `transition` | BiomeShift | Parallax fade + intro del siguiente bioma |
| `boss` | DreadnoughtApproach | Warning UI + spawn Dreadnought |

**Referencia de patrón:** `.agent/skills/godot-procedural-generation.md`

**Archivos a crear/modificar:**
- `scripts/data/level_chunk.gd` — ampliar con campos de diseño de olas
- `resources/chunks/chunk-open-lane.tres` (y los 5 restantes)
- `scripts/gameplay/chunk_manager.gd` — lógica de streaming y culling
- `scripts/gameplay/encounter_director.gd` — refactorizar para delegar a `ChunkManager`

**EventBus — señales nuevas:**
```gdscript
signal chunk_started(chunk: LevelChunk)
signal chunk_completed(chunk: LevelChunk)
signal biome_transition_started(next_biome: BiomeProfile)
```

**Criterios de aceptación:**
- [ ] Niveles generados por concatenación de chunks (no timer fijo)
- [ ] Max 3 chunks en memoria simultáneamente
- [ ] Respeta heat level para selección de chunks
- [ ] Boss chunk siempre termina la secuencia
- [ ] 60 FPS durante transición de chunks

---

### M23 — Workshop y Metaprogresión
**Objetivo:** Cerrar el loop roguelite: scrap → upgrades permanentes → Omega Protocol.

**Arquitectura — SaveManager (nuevo autoload):**
```gdscript
# autoloads/save_manager.gd
# NOTA: No usar class_name en singletons (bug documentado — ver commit 9fcd6ed)
extends Node
var total_scrap: int = 0
var permanent_upgrades: Array[StringName] = []
var heat_unlocked: int = 0
var settings: Dictionary = {}
func save() -> void: # JSON + SHA-256 checksum
func load_data() -> void: # Verificar checksum, cargar datos
```

**6 mejoras permanentes del Workshop:**
| ID | Nombre | Efecto Permanente |
|----|--------|-------------------|
| `quantum_dash` | Quantum Dash | Dash invulnerability 0.15s → 0.25s |
| `singularity_shield` | Singularity Shield | 1 hit gratis por run (no-damage) |
| `kinetic_synergy` | Kinetic Synergy | Force bounce recarga Wave Cannon |
| `dual_charge` | Dual Charge Capsule | Cargar 2 Wave Cannons simultáneos |
| `claw_armor` | Claw Armor | Hitbox efectivo 4×4 → 2×2 |
| `flank_sensor` | Flank Sensor | Indicador de proyectiles fuera de pantalla |

**Omega Protocol (5 niveles):**
| Nivel | Nombre | Modificador |
|-------|--------|-------------|
| 0 | Protocolo Estándar | Base (sin modificaciones) |
| 1 | Protocolo Rojo | Enemigos +20% velocidad, scrap ×1.2 |
| 2 | Protocolo Escarlata | Torretas disparan doble, scrap ×1.5 |
| 3 | Protocolo Carmesí | Dreadnought Fase 4 activada (Colapso Crítico), scrap ×2.0 |
| 4 | Protocolo Ébano | Regeneración de enemigos, hitbox player ×1.5, scrap ×3.0 |

**Pantallas nuevas:**
- `scenes/ui/WorkshopScreen.tscn` + `workshop_screen.gd`
- `scenes/ui/OmegaProtocolScreen.tscn` + `omega_protocol_screen.gd`

**Screen flow actualizado:**
```
ResultScreen → WorkshopScreen → OmegaProtocolScreen → ShipSelect → Main
```

**Archivos a crear/modificar:**
- `autoloads/save_manager.gd` — persistencia JSON + SHA-256
- `scenes/ui/WorkshopScreen.tscn` + `workshop_screen.gd`
- `scenes/ui/OmegaProtocolScreen.tscn` + `omega_protocol_screen.gd`
- `autoloads/run_manager.gd` — integrar `heat_level`, `active_upgrades` permanentes
- `autoloads/game_state.gd` — añadir referencia a `SaveManager`

**Criterios de aceptación:**
- [ ] Scrap persiste entre runs (SaveManager + JSON)
- [ ] 6 upgrades comprables y aplicadas en runtime
- [ ] Omega Protocol modifica parámetros de juego correctamente
- [ ] Protocolo 3+ activa Fase 4 del Dreadnought (Colapso Crítico)
- [ ] Checksum SHA-256 previene save editing
- [ ] WorkshopScreen → loop de vuelta a ShipSelect funcional

---

## Resumen de Dependencias

```
M17 (Audio) → M18 (Force) → M19 (Biomas)
                                  ↓
                    ┌─────────────┼─────────────┐
                  M20           M21            M22
               (PowerUps)   (Enemigos)       (Chunks)
                    └─────────────┴─────────────┘
                                  ↓
                               M23 (Workshop)
```

M20 y M21 pueden desarrollarse en paralelo después de M19.
M22 depende de M21 (nuevos enemigos deben existir para los chunks).
M23 depende de M20 + M22 (economía + nivel infinito cierran el loop).
