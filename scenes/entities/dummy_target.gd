class_name DummyTarget
extends Area2D

var _hp: int = 3


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()
