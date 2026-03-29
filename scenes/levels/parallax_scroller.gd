extends ParallaxBackground

## Drives the three-layer parallax starfield for Valkyrie-VII.
## Scroll is purely horizontal (right-to-left warp effect).
## Framerate-independent: all movement multiplied by delta.
##
## Uses motion_offset on each ParallaxLayer directly — NOT scroll_offset.
## In Godot 4, scroll_offset is a flat additive that bypasses motion_scale,
## so all layers would scroll at identical speed. Per-layer motion_offset
## accumulation is the correct API for depth-differentiated auto-scroll.
## motion_scale is intentionally kept in the scene so camera-shake
## (CameraShake.gd offset ±16px) produces a natural spatial depth response.

const SCROLL_SPEED: float = 500.0

const CANVAS_W: int = 1920
const CANVAS_H: int = 1080

const DISTANT_STAR_COUNT: int = 300
const DISTANT_SEED: int = 111

const NEAR_STAR_COUNT: int = 150
const NEAR_SEED: int = 222
const NEAR_YELLOW_CHANCE: float = 0.15

# Scroll speed multipliers per layer — ratio controls parallax depth illusion
const DISTANT_SPEED_FACTOR: float = 0.2  # 100 px/s — barely drifting
const NEBULA_SPEED_FACTOR: float = 0.5   # 250 px/s — mid-ground clouds
const NEAR_SPEED_FACTOR: float = 1.0     # 500 px/s — streaking foreground

@onready var _stars_distant: ParallaxLayer = $StarsDistant
@onready var _nebula: ParallaxLayer = $Nebula
@onready var _stars_near: ParallaxLayer = $StarsNear


func _ready() -> void:
	_generate_distant_stars()
	_generate_near_stars()
	EventBus.biome_transition_requested.connect(_on_biome_transition_requested)


func _on_biome_transition_requested(profile: Resource) -> void:
	var biome: BiomeProfile = profile as BiomeProfile
	if biome == null:
		return
	self.modulate = biome.accent_color
	if biome.parallax_layers.size() > 0 and biome.parallax_layers[0] != null:
		_nebula.get_node("NebulaSprite").texture = biome.parallax_layers[0]


func _process(delta: float) -> void:
	var base: float = SCROLL_SPEED * delta
	_stars_distant.motion_offset.x -= base * DISTANT_SPEED_FACTOR
	_nebula.motion_offset.x -= base * NEBULA_SPEED_FACTOR
	_stars_near.motion_offset.x -= base * NEAR_SPEED_FACTOR


## Generates 300 single-pixel cool-white stars on a transparent canvas.
## Deterministic seed ensures identical layout across runs.
func _generate_distant_stars() -> void:
	var img: Image = Image.create(CANVAS_W, CANVAS_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = DISTANT_SEED
	for _i: int in DISTANT_STAR_COUNT:
		var x: int = rng.randi_range(0, CANVAS_W - 1)
		var y: int = rng.randi_range(0, CANVAS_H - 1)
		var alpha: float = rng.randf_range(0.5, 0.7)
		img.set_pixel(x, y, Color(0.85, 0.9, 1.0, alpha))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_stars_distant.get_node("StarSprite").texture = tex


## Generates 150 two-by-two-pixel stars, 15% chance of yellow-white tint.
## Larger pixels + faster speed = strong depth contrast vs distant layer.
func _generate_near_stars() -> void:
	var img: Image = Image.create(CANVAS_W, CANVAS_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = NEAR_SEED
	for _i: int in NEAR_STAR_COUNT:
		var x: int = rng.randi_range(0, CANVAS_W - 2)
		var y: int = rng.randi_range(0, CANVAS_H - 2)
		var alpha: float = rng.randf_range(0.85, 1.0)
		var color: Color
		if rng.randf() < NEAR_YELLOW_CHANCE:
			color = Color(1.0, 0.95, 0.7, alpha)
		else:
			color = Color(1.0, 1.0, 1.0, alpha)
		# 2×2 block for a chunkier, closer-star arcade feel
		img.set_pixel(x, y, color)
		img.set_pixel(x + 1, y, color)
		img.set_pixel(x, y + 1, color)
		img.set_pixel(x + 1, y + 1, color)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_stars_near.get_node("NearSprite").texture = tex
