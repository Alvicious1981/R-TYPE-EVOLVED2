# Skill: Godot Object Pool (BulletPoolManager)

## Problema
En un shmup bullet-hell, instanciar y destruir proyectiles con `add_child()`/`queue_free()` en tiempo real
destruye el Garbage Collector de Godot y provoca micro-stutters que arruinan la experiencia táctica.

## Solución: Object Pool

`BulletPoolManager` es un **Autoload Singleton** pre-instancia `POOL_SIZE = 2000` balas inactivas
al cargar el nivel. Las balas nunca se destruyen; se reciclan.

## API

```gdscript
# Solicitar bala del pool
var bullet: Node = BulletPoolManager.get_bullet(type, pos, dir)

# Devolver bala al pool (llamar desde Bullet al impactar o salir del viewport)
BulletPoolManager.return_bullet(bullet)
```

## Reglas

- **Nunca** usar `add_child()` / `queue_free()` para proyectiles
- Si `_available.is_empty()`: loguear warning y descartar — nunca instanciar dinámicamente
- Pools independientes: balas del jugador | balas enemigas estándar | balas de jefe
- La bala desactivada: deshabilita colisiones, se oculta, resetea estado

## Implementación Futura (Hito de Gameplay)

```gdscript
# autoloads/bullet_pool_manager.gd
class_name BulletPoolManager
extends Node

const POOL_SIZE: int = 2000
var _available: Array[Bullet] = []  # Typed Array[Bullet] cuando exista la clase
var _active: Array[Bullet] = []

func get_bullet(type: BulletType, pos: Vector2, dir: Vector2) -> Bullet:
    if _available.is_empty():
        push_warning("BulletPool exhausted — consider increasing POOL_SIZE")
        return null
    var bullet: Bullet = _available.pop_back()
    bullet.initialize(type, pos, dir)
    _active.append(bullet)
    return bullet

func return_bullet(bullet: Bullet) -> void:
    bullet.deactivate()
    _active.erase(bullet)
    _available.append(bullet)
```

## Referencias

- TDD Valkyrie-VII §2.1 — BulletPoolManager
- TDD §2.2 — PhysicsServer2D y RenderingServer para ataques masivos de jefe
