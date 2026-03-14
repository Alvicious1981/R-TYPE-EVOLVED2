# Skill: FSM Ligera para IA Enemiga (Godot 4.x)

## Problema
La IA enemiga necesita gestionar estados (idle, patrol, chase, attack, death) de forma eficiente.
Usar `if/else` anidados en `_process()` no escala y genera deuda técnica.

## Solución: FSM con Enum + Dispatch

Estado como enum SCREAMING_SNAKE_CASE. Dispatch en `_physics_process()`.
Actualización cada **2 ticks para fodder** (drones, zánganos) para ahorrar CPU.

## Patrón Base

```gdscript
class_name EnemyBase
extends CharacterBody2D

enum State {
    IDLE,
    PATROL,
    CHASE,
    ATTACK,
    DEAD,
}

var current_state: State = State.IDLE
var _tick_counter: int = 0
const FODDER_TICK_RATE: int = 2  # Actualizar cada 2 ticks para fodder

func _physics_process(_delta: float) -> void:
    _tick_counter += 1
    if _tick_counter < FODDER_TICK_RATE:
        return
    _tick_counter = 0

    match current_state:
        State.IDLE:   _state_idle()
        State.PATROL: _state_patrol()
        State.CHASE:  _state_chase()
        State.ATTACK: _state_attack()
        State.DEAD:   _state_dead()

func _transition_to(new_state: State) -> void:
    current_state = new_state

func _state_idle() -> void:
    pass  # Implementar por subclase o EnemyProfile

func _state_patrol() -> void:
    pass

func _state_chase() -> void:
    pass

func _state_attack() -> void:
    pass

func _state_dead() -> void:
    pass
```

## Reglas

- Jefes (Dreadnoughts): `FODDER_TICK_RATE = 1` (actualización por tick)
- Fodder (zánganos, torretas): `FODDER_TICK_RATE = 2`
- Transición de estado mediante `_transition_to()` — nunca modificar `current_state` directamente
- Emitir señal `enemy_destroyed` al entrar en `State.DEAD`

## Referencias

- TDD Valkyrie-VII §2.3 — Presupuesto de rendimiento (IA enemiga < 2.0 ms/frame)
- PRD §3 — Tipos de enemigos: Zánganos, Torretas, Dreadnoughts
