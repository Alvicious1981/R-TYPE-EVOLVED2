extends Node

signal score_changed(new_score: int)

var current_score: int = 0
var active_power_ups: Array[UpgradeData] = []

## Tiempos restantes mapeados por effect_type: Dictionary[StringName, float]
var _power_up_times: Dictionary = {}


func _process(delta: float) -> void:
	var to_expire: Array[StringName] = []
	
	for effect_type: StringName in _power_up_times:
		_power_up_times[effect_type] -= delta
		if _power_up_times[effect_type] <= 0.0:
			to_expire.append(effect_type)
	
	for effect_type in to_expire:
		var data: UpgradeData = _find_active_upgrade(effect_type)
		if data != null:
			_expire_power_up(data)


func _ready() -> void:
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.power_up_collected.connect(_on_power_up_collected)


func _on_enemy_destroyed(score_value: int, _position: Vector2) -> void:
	add_score(score_value)


func add_score(value: int) -> void:
	current_score += value
	score_changed.emit(current_score)


func reset() -> void:
	current_score = 0
	active_power_ups.clear()
	_power_up_times.clear()
	score_changed.emit(0)


func _on_power_up_collected(data: UpgradeData) -> void:
	var player: Player = _get_player()
	if player == null:
		push_warning("[RunManager] power_up_collected but Player not found in group 'player'")
		return
	
	# Si ya está activo, solo refrescamos el tiempo si tiene uno.
	if _find_active_upgrade(data.effect_type) != null:
		if data.duration > 0.0:
			_power_up_times[data.effect_type] = data.duration
		return
	
	# Si es nuevo, aplicamos y registramos.
	player.apply_powerup(data)
	active_power_ups.append(data)
	
	if data.duration > 0.0:
		_power_up_times[data.effect_type] = data.duration


func _expire_power_up(data: UpgradeData) -> void:
	var player: Player = _get_player()
	if player != null:
		player.revert_powerup(data)
	
	active_power_ups.erase(data)
	_power_up_times.erase(data.effect_type)
	EventBus.power_up_expired.emit(data)


## Llamado por Player cuando pu_shield_pulse absorbe un golpe (duración -1, sin timer).
func notify_shield_consumed() -> void:
	var data: UpgradeData = _find_active_upgrade(&"pu_shield_pulse")
	if data != null:
		_expire_power_up(data)


## Devuelve el tiempo restante de un power-up activo. 0.0 si es permanente u oculto.
func get_power_up_time_left(effect_type: StringName) -> float:
	return _power_up_times.get(effect_type, 0.0)


func _find_active_upgrade(effect_type: StringName) -> UpgradeData:
	for pu in active_power_ups:
		if pu.effect_type == effect_type:
			return pu
	return null


func _get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player
