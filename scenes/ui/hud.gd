extends CanvasLayer

const ENCOUNTER_END: float = 45.0

@onready var _timer_label: Label = $TimerLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _run_complete_label: Label = $RunCompleteLabel


func _ready() -> void:
	RunManager.score_changed.connect(_on_score_changed)


func _process(_delta: float) -> void:
	var director: Node = get_parent().get_node_or_null("EncounterDirector")
	if director == null:
		return
	var elapsed: float = float(director.get("_elapsed"))
	var remaining: float = maxf(ENCOUNTER_END - elapsed, 0.0)
	_timer_label.text = "T  %02d" % int(remaining)


func show_run_complete() -> void:
	_run_complete_label.visible = true
	_timer_label.text = "T  00"


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "SC  %d" % new_score
