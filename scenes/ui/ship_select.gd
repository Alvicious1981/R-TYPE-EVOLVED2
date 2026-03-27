class_name ShipSelect extends Node2D

const SHIP_CONFIG_PATHS: Array[String] = [
	"res://resources/ships/ship-config-1.tres",
	"res://resources/ships/ship-config-2.tres",
	"res://resources/ships/ship-config-3.tres",
	"res://resources/ships/ship-config-4.tres",
	"res://resources/ships/ship-config-5.tres",
]

@onready var _preview: Sprite2D = $ShipPreview
@onready var _name_label: Label = $ShipNameLabel

var _current_index: int = 0
var _configs: Array = []


func _ready() -> void:
	for path: String in SHIP_CONFIG_PATHS:
		_configs.append(load(path))
	_current_index = GameState.selected_ship_index
	_refresh_display()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_navigate(-1)
	elif event.is_action_pressed("ui_right"):
		_navigate(1)
	elif event.is_action_pressed("ui_accept"):
		_on_launch_pressed()


func _navigate(direction: int) -> void:
	_current_index = (_current_index + direction + _configs.size()) % _configs.size()
	_refresh_display()


func _refresh_display() -> void:
	var cfg: Resource = _configs[_current_index] as Resource
	var tex_path: String = cfg.get("texture_path") as String
	var disp_scale: Vector2 = cfg.get("display_scale") as Vector2
	_preview.texture = load(tex_path) as Texture2D
	_preview.scale = disp_scale * 8.0
	_name_label.text = cfg.get("ship_name") as String


func _on_launch_pressed() -> void:
	GameState.selected_ship_index = _current_index
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_left_arrow_pressed() -> void:
	_navigate(-1)


func _on_right_arrow_pressed() -> void:
	_navigate(1)
