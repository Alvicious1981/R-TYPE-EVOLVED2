# Fix: Bala no destruye Zángano — M3 Bug

**Estado:** FIX APLICADO Y VERIFICADO (2026-03-19)

## Causa Raíz

`Bullet` es un `Area2D`. El signal `area_entered` **solo detecta otros `Area2D`**.
`EnemyBase` es un `CharacterBody2D` (PhysicsBody2D), que dispara `body_entered`, no `area_entered`.

Resultado: la colisión entre bala y zángano nunca activa el callback, nunca se llama `take_damage()`.

## Verificación de layers/masks

| Nodo | collision_layer | collision_mask |
|---|---|---|
| Bullet (Area2D) | 2 (Municion_Aliada) | 4 (Chasis_Hostil) ✅ |
| EnemyBase (CharacterBody2D) | 4 (Chasis_Hostil) ✅ | 0 |

Las máscaras son correctas. El problema es el signal, no la configuración de capas.

## Fix

**Un solo archivo:** `scenes/entities/bullet.gd`

Agregar en `_ready()`:
```gdscript
body_entered.connect(_on_body_entered)
```

Agregar función:
```gdscript
func _on_body_entered(body: Node2D) -> void:
    if not visible:
        return
    if body.has_method("take_damage"):
        body.take_damage(_damage)
    BulletPoolManager.return_bullet(self)
```

## Archivos tocados

- `scenes/entities/bullet.gd` — único archivo modificado

## Verificación (2026-03-19)

Verificado manualmente en todos los archivos fuente:

| Check | Resultado |
|---|---|
| `bullet.gd` tiene `body_entered.connect(_on_body_entered)` | ✅ PRESENTE en línea 11 |
| `bullet.gd` tiene `_on_body_entered(body: Node2D)` con guard `if not visible` | ✅ PRESENTE líneas 45-50 |
| `Bullet.tscn` — `collision_mask = 4` (Layer 3) | ✅ correcto |
| `EnemyBase.tscn` — `collision_layer = 4` (Layer 3) | ✅ correcto |
| `EnemyBase.tscn` — CollisionShape2D activo (no disabled) | ✅ correcto |
| `Bullet.tscn` — CollisionShape2D activo (no disabled) | ✅ correcto |
| `enemy-zangano.tres` — `max_hp = 1` | ✅ correcto |
| `encounter_director.gd` asigna `profile` antes de `add_child()` | ✅ correcto |
| `enemy_base.gd` — `_current_hp = profile.max_hp` en `_ready()` | ✅ correcto |
| `enemy_base.gd` — `take_damage()` llama `queue_free()` cuando hp <= 0 | ✅ correcto |
| `RunManager` — autoload registrado en `project.godot` | ✅ correcto |

**Conclusión**: El fix está aplicado. El sistema de colisión bala → zángano es correcto en código.

## Criterio de aceptación

- Una bala impacta al zángano → `take_damage()` se llama → `_current_hp` llega a 0 → `queue_free()` → zángano desaparece.
- Sin errores rojos. Sin nuevas features.
