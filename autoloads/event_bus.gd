extends Node

signal enemy_destroyed(score_value: int, position: Vector2)
signal boss_phase_changed(new_phase: int)
signal boss_defeated()
signal player_shoot()
signal player_died()
signal wave_charge_started()
signal wave_charge_changed(level: int)
signal wave_cannon_fired(level: int, power: float)
signal wave_cannon_cancelled()
