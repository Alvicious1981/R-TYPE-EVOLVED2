# Skill: Arquitectura Data-Driven con Clases Resource

## Problema
Hardcodear estadísticas de enemigos, armas y upgrades en scripts GDScript o escenas .tscn:
- Acopla datos con lógica
- Requiere tocar código para ajustar balance
- Imposibilita reutilizar una única escena base para múltiples variantes

## Solución: Resource como Contenedor de Datos

Las clases `extends Resource` actúan como DTOs (Data Transfer Objects) serializables.
Una sola escena `Enemy.tscn` inyecta un `EnemyProfile` en `_ready()` y adopta sus estadísticas.

## Separación de Responsabilidades

| Directorio | Contenido |
|------------|-----------|
| `scripts/data/` | Clases .gd con `class_name X extends Resource` + `@export` |
| `resources/enemies/` | Archivos .tres con datos concretos (enemy-zangano.tres) |
| `scenes/entities/` | Escena base única (Enemy.tscn) que consume el Resource |

## Patrón de Inyección

```gdscript
# scripts/data/enemy_profile.gd
class_name EnemyProfile
extends Resource

@export var id: String = ""
@export var max_hp: int = 0
@export var point_value: int = 0
```

```gdscript
# scenes/entities/enemies/EnemyBase.gd
class_name EnemyBase
extends CharacterBody2D

@export var profile: EnemyProfile  # Asignado en el inspector o por el spawner

func _ready() -> void:
    if profile == null:
        push_error("EnemyBase requires an EnemyProfile resource")
        return
    _apply_profile(profile)

func _apply_profile(p: EnemyProfile) -> void:
    # Aplicar stats del Resource a la instancia
    pass
```

## Clases Resource del Proyecto (TDD §1.1)

| Clase | Archivo | Datos clave |
|-------|---------|-------------|
| `EnemyProfile` | `scripts/data/enemy_profile.gd` | id, max_hp, point_value, projectile_pattern |
| `WeaponStats` | `scripts/data/weapon_stats.gd` | fire_rate, damage, spread_angle, projectile_speed |
| `UpgradeData` | `scripts/data/upgrade_data.gd` | id, cost_scrap, icon, stat_modifier_dict |
| `LevelChunk` | `scripts/data/level_chunk.gd` | chunk_scene, heat_level_req, spawn_weight |
| `ForceConfig` | `scripts/data/force_config.gd` | mode (enum), energy_drain_rate, bounce_charge_gain |

## Reglas

- Nunca lógica de juego en clases Resource — solo datos y @export
- Archivos .tres en kebab-case: `enemy-zangano.tres`, `upgrade-dash.tres`
- Modificaciones de balance = editar el .tres en el inspector, no tocar código

## Referencias

- TDD Valkyrie-VII §1.1 — Arquitectura Data-Driven
