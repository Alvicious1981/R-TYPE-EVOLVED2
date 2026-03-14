# Skill: Convenciones GDScript — Valkyrie-VII

Resumen operativo de las convenciones del TDD §1.2. Aplicar sin excepción.

## Tipado Estricto Obligatorio

Todo el código GDScript usa tipado estático:

```gdscript
# Correcto
var health: int = 100
var speed: float = 200.0
var is_active: bool = false
func take_damage(amount: int) -> void:
func get_position() -> Vector2:

# Incorrecto — nunca sin tipo
var health = 100
func take_damage(amount):
```

## Nomenclatura

| Elemento | Convención | Correcto | Incorrecto |
|----------|-----------|----------|------------|
| Clases y Nodos | PascalCase | `EnemyDreadnought` | `enemy_dreadnought` |
| Variables | snake_case | `current_health` | `currentHealth` |
| Funciones | snake_case | `fire_rate`, `_on_timer_timeout()` | `fireRate` |
| Constantes | SCREAMING_SNAKE_CASE | `MAX_SPEED`, `POOL_SIZE` | `max_speed` |
| Enumeradores | SCREAMING_SNAKE_CASE | `ForceMode.DETACHED` | `ForceMode.detached` |
| Señales | snake_case descriptivo | `health_changed`, `enemy_destroyed` | `healthChanged` |
| Recursos .tres | kebab-case | `enemy-zangano.tres` | `EnemyZangano.tres` |
| Escenas .tscn | PascalCase | `EnemyBase.tscn` | `enemy_base.tscn` |

## Señales

```gdscript
# Definición
signal health_changed(new_health: int)
signal enemy_destroyed(points: int)
signal boss_phase_entered(phase: int)

# Emisión
health_changed.emit(current_health)
```

## Collision Layers (TDD §3)

6 capas definidas en Project Settings. **Nunca modificar por código en runtime.**

| Layer | Nombre | Escanea |
|-------|--------|---------|
| 1 | Jugador_Nucleo | 3, 4, 6 |
| 2 | Municion_Aliada | 3, 6 |
| 3 | Chasis_Hostil | 1, 2, 5 |
| 4 | Municion_Biomecanica | 1, 5 |
| 5 | Modulo_Tactico_Force | 3, 4, 6 |
| 6 | Terreno_Solido | — (estático) |

Configurar `collision_layer` y `collision_mask` en el inspector de cada escena, **no en código**.

## Estructura de Autoloads

Los Autoloads se registran en `project.godot` bajo `[autoload]` y viven en `autoloads/`:
```
BulletPoolManager="*res://autoloads/bullet_pool_manager.gd"
```
El prefijo `*` indica que es un singleton que se instancia automáticamente.

## Prefijos de Funciones

| Prefijo | Significado |
|---------|-------------|
| `_` | Privado / override de Godot (`_ready`, `_physics_process`) |
| Sin prefijo | Público / API del nodo |
| `_on_` | Callback de señal conectada (`_on_timer_timeout`) |

## Referencias

- TDD Valkyrie-VII §1.2 — Convenciones de Nomenclatura
- TDD §3 — Matriz de Colisiones
