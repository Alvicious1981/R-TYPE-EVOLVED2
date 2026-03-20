extends CanvasLayer

@onready var _rect: ColorRect = $ColorRect


func _ready() -> void:
	EventBus.boss_phase_changed.connect(_on_phase_changed)


func _on_phase_changed(_new_phase: int) -> void:
	flash()


func flash() -> void:
	_rect.modulate.a = 0.85
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, 0.35)
