# scripts/gameplay/loot_table.gd
## Stub M20: drop plano 15%. M21/M22 inyectarán pesos por heat level
## sin modificar EnemyBase — solo extender este archivo.
class_name LootTable

const DROP_CHANCE: float = 0.15

## Pool fijo M20. M21: reemplazar por Array ponderado por heat.
const _POWER_UP_PATHS: Array[String] = [
	"res://resources/upgrades/pu-rapid-fire.tres",
	"res://resources/upgrades/pu-speed-boost.tres",
	"res://resources/upgrades/pu-shield-pulse.tres",
	"res://resources/upgrades/pu-scrap-magnet.tres",
	"res://resources/upgrades/pu-wave-amp.tres",
]

const _PICKUP_SCENE_PATH: String = "res://scenes/entities/PowerUpPickup.tscn"


## Punto de entrada desde EnemyBase. M21/M22: añadir parámetro heat_level: int = 0.
static func try_drop(position: Vector2, parent: Node) -> void:
	if randf() > DROP_CHANCE:
		return
	var idx: int = randi() % _POWER_UP_PATHS.size()
	var data: UpgradeData = load(_POWER_UP_PATHS[idx]) as UpgradeData
	if data == null:
		push_error("[LootTable] Failed to load power-up at index %d" % idx)
		return
	var scene: PackedScene = load(_PICKUP_SCENE_PATH) as PackedScene
	var pickup: PowerUpPickup = scene.instantiate() as PowerUpPickup
	pickup.init(data)
	parent.add_child(pickup)
	pickup.global_position = position
