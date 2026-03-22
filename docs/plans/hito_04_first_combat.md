# Hito 04 — Primer Intercambio de Combate Real

**Fecha:** 2026-03-16
**Agente:** Planner → Worker → Validator

## Objetivo

Crear el primer intercambio de combate completo: el Zángano dispara al jugador, el jugador puede ser destruido, y puede reiniciar la partida con R.

## Amenaza elegida

**Disparo enemigo** — EnemyBullet (Area2D, Layer 4 / Municion_Biomecanica, mask Layer 1 / Jugador_Nucleo).

## Skeleton of Thought

```
EnemyBullet (scene + script)
  → BulletPoolManager (enemy pool)
    → EnemyBase (_shoot → pool)
      → Player (take_damage, _die, restart)
        → Player.tscn (DeathLayer CanvasLayer)
          → project.godot (ui_restart action)
```

## Archivos

### Crear
| Archivo | Propósito |
|---------|-----------|
| `scenes/entities/enemy_bullet.gd` | Clase EnemyBullet — Area2D, layer=8, mask=1 |
| `scenes/entities/EnemyBullet.tscn` | Escena instanciada por BulletPoolManager |

### Modificar
| Archivo | Cambio clave |
|---------|-------------|
| `project.godot` | `ui_restart` = KEY_R (physical_keycode=82) |
| `autoloads/bullet_pool_manager.gd` | ENEMY_POOL_SIZE=500, `get_enemy_bullet` / `return_enemy_bullet` |
| `scenes/entities/Player.tscn` | DeathLayer (CanvasLayer layer=10) > FlashOverlay + DeathLabel |
| `scenes/entities/player.gd` | MAX_HP=3, take_damage, flash 0.15s, _die, reload_current_scene |
| `scenes/entities/enemy_base.gd` | FIRE_INTERVAL=1.5s, randf stagger, _shoot apuntando al jugador |

## Collision layers (bit values)

| Layer | Nombre | Valor |
|-------|--------|-------|
| 1 | Jugador_Nucleo | 1 |
| 2 | Municion_Aliada | 2 |
| 3 | Chasis_Hostil | 4 |
| 4 | Municion_Biomecanica | 8 |

EnemyBullet: `collision_layer=8`, `collision_mask=1`

## Criterios de aceptación

- [ ] F5 sin errores rojos
- [ ] Zángano dispara balas rojas cada ~1.5s
- [ ] 3 impactos → "DESTROYED — Press R"
- [ ] R reinicia escena
- [ ] Flash rojo al recibir daño
- [ ] Jugador puede destruir Zánganos (M3 no roto)
- [ ] Ciclo prueba < 30 segundos

## Restricciones

- Sin EventBus, sin score, sin HUD final, sin RunManager
- Sin add_child/queue_free para proyectiles (usar BulletPoolManager)
- Tipado estático GDScript en todo el código nuevo
