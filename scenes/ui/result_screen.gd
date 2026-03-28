class_name ResultScreen extends Node2D

const RANK_S_THRESHOLD: int = 5000
const RANK_A_THRESHOLD: int = 3000
const RANK_B_THRESHOLD: int = 1000

@onready var _outcome_label: Label = $OutcomeLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _rank_label: Label = $RankLabel


func _ready() -> void:
	var score: int = GameState.final_score
	var victory: bool = GameState.run_victory

	if victory:
		_outcome_label.text = "MISSION  COMPLETE"
		_outcome_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1))
	else:
		_outcome_label.text = "MISSION  FAILED"
		_outcome_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))

	_score_label.text = "SCORE   %d" % score

	var rank: String = _calculate_rank(score)
	_rank_label.text = rank
	_rank_label.add_theme_color_override("font_color", _rank_color(rank))


func _calculate_rank(score: int) -> String:
	if score >= RANK_S_THRESHOLD:
		return "S"
	elif score >= RANK_A_THRESHOLD:
		return "A"
	elif score >= RANK_B_THRESHOLD:
		return "B"
	else:
		return "C"


func _rank_color(rank: String) -> Color:
	match rank:
		"S": return Color(1.0, 0.9, 0.2, 1)
		"A": return Color(0.4, 0.8, 1.0, 1)
		"B": return Color(0.5, 1.0, 0.5, 1)
		_:   return Color(0.8, 0.8, 0.8, 1)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_restart"):
		GameState.final_score = 0
		GameState.run_victory = false
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	elif event.is_action_pressed("ui_cancel"):
		GameState.final_score = 0
		GameState.run_victory = false
		get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
