extends Node2D

const STAR_COUNT: int = 200
const SCROLL_SPEED: float = 60.0

var _stars: Array[Vector2] = []
var _scroll_x: float = 0.0


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	for _i: int in STAR_COUNT:
		_stars.append(Vector2(rng.randf_range(0.0, 1920.0), rng.randf_range(0.0, 1080.0)))


func _process(delta: float) -> void:
	_scroll_x = fmod(_scroll_x + SCROLL_SPEED * delta, 1920.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)), Color(0.02, 0.02, 0.08, 1.0))
	for star: Vector2 in _stars:
		var x: float = fmod(star.x - _scroll_x + 1920.0, 1920.0)
		draw_circle(Vector2(x, star.y), 1.5, Color(0.85, 0.9, 1.0, 0.7))
