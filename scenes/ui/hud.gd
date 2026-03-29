extends CanvasLayer

const ENCOUNTER_END: float = 45.0

## Color por effect_type — mirrors PowerUpPickup.EFFECT_COLORS
const EFFECT_COLORS: Dictionary = {
	&"pu_rapid_fire":   Color(1.0, 0.5, 0.0),
	&"pu_speed_boost":  Color(0.0, 1.0, 1.0),
	&"pu_shield_pulse": Color(0.2, 0.6, 1.0),
	&"pu_scrap_magnet": Color(0.8, 1.0, 0.2),
	&"pu_wave_amp":     Color(1.0, 0.2, 1.0),
}

@onready var _timer_label: Label = $TimerLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _run_complete_label: Label = $RunCompleteLabel
@onready var _power_up_panel: HBoxContainer = $PowerUpPanel

## Entradas activas: effect_type → VBoxContainer
var _power_up_entries: Dictionary = {}


func _ready() -> void:
	RunManager.score_changed.connect(_on_score_changed)
	EventBus.power_up_collected.connect(_on_power_up_collected)
	EventBus.power_up_expired.connect(_on_power_up_expired)


func _process(_delta: float) -> void:
	var director: Node = get_parent().get_node_or_null("EncounterDirector")
	if director != null:
		var elapsed: float = float(director.get("_elapsed"))
		var remaining: float = maxf(ENCOUNTER_END - elapsed, 0.0)
		_timer_label.text = "T  %02d" % int(remaining)

	for effect_type: StringName in _power_up_entries:
		var entry: VBoxContainer = _power_up_entries[effect_type] as VBoxContainer
		var time_label: Label = entry.get_node_or_null("TimeLabel") as Label
		if time_label == null:
			continue
		var time_left: float = RunManager.get_power_up_time_left(effect_type)
		if time_left > 0.0:
			time_label.text = "%ds" % int(ceilf(time_left))
		else:
			time_label.text = "∞"


func show_run_complete() -> void:
	_run_complete_label.visible = true
	_timer_label.text = "T  00"


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "SC  %d" % new_score


func _on_power_up_collected(data: UpgradeData) -> void:
	if _power_up_entries.has(data.effect_type):
		return  # ya activo — no duplicar entrada
	var entry: VBoxContainer = VBoxContainer.new()
	entry.name = str(data.effect_type)

	var rect: ColorRect = ColorRect.new()
	rect.custom_minimum_size = Vector2(28.0, 28.0)
	rect.color = EFFECT_COLORS.get(data.effect_type, Color.WHITE)
	entry.add_child(rect)

	var label: Label = Label.new()
	label.name = "TimeLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.text = "∞" if data.duration < 0.0 else "%ds" % int(data.duration)
	entry.add_child(label)

	_power_up_panel.add_child(entry)
	_power_up_entries[data.effect_type] = entry


func _on_power_up_expired(data: UpgradeData) -> void:
	if _power_up_entries.has(data.effect_type):
		(_power_up_entries[data.effect_type] as VBoxContainer).queue_free()
		_power_up_entries.erase(data.effect_type)
