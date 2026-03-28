class_name TitleScreen extends Node2D

@onready var _press_start: Label = $PressStartLabel


func _ready() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_press_start, "modulate:a", 0.0, 0.5)
	tween.tween_property(_press_start, "modulate:a", 1.0, 0.5)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/ui/ShipSelect.tscn")
