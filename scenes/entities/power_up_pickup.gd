# scenes/entities/power_up_pickup.gd
class_name PowerUpPickup
extends Area2D

const DRIFT_SPEED: float = 60.0

## Color visual por effect_type — visual placeholder hasta M21 (sprites reales)
const EFFECT_COLORS: Dictionary = {
	&"pu_rapid_fire":   Color(1.0, 0.5, 0.0),
	&"pu_speed_boost":  Color(0.0, 1.0, 1.0),
	&"pu_shield_pulse": Color(0.2, 0.6, 1.0),
	&"pu_scrap_magnet": Color(0.8, 1.0, 0.2),
	&"pu_wave_amp":     Color(1.0, 0.2, 1.0),
}

var upgrade_data: UpgradeData


## Llamar antes de add_child() para inyectar el resource.
func init(data: UpgradeData) -> void:
	upgrade_data = data


func _ready() -> void:
	if upgrade_data != null:
		$ColorRect.color = EFFECT_COLORS.get(upgrade_data.effect_type, Color.WHITE)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.x -= DRIFT_SPEED * delta
	if global_position.x < -100.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.power_up_collected.emit(upgrade_data)
		queue_free()
