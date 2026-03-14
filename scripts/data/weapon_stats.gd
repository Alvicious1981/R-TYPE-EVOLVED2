class_name WeaponStats
extends Resource

## Define parámetros de arma separados del script de la nave.
## Modificable en tiempo real por upgrades sin tocar código. (TDD §1.1)

@export var fire_rate: float = 0.0
@export var damage: int = 0
@export var spread_angle: float = 0.0
@export var projectile_speed: float = 0.0
