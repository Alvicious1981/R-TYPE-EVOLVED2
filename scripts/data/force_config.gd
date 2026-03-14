class_name ForceConfig
extends Resource

## Parametriza el comportamiento del Módulo Force según el protocolo activo. (TDD §1.1)

enum ForceMode {
	ATTACHED,
	DETACHED,
	LAUNCHED,
}

@export var mode: ForceMode = ForceMode.ATTACHED
@export var energy_drain_rate: float = 0.0
@export var bounce_charge_gain: float = 0.0
