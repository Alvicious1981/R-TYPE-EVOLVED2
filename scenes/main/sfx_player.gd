class_name SfxPlayer extends Node

const MIX_RATE: float = 44100.0
const SHOOT_COOLDOWN_TIME: float = 0.15

@onready var _sfx_shoot: AudioStreamPlayer = $SFX_Shoot
@onready var _sfx_enemy_death: AudioStreamPlayer = $SFX_EnemyDeath
@onready var _sfx_player_death: AudioStreamPlayer = $SFX_PlayerDeath

var _shoot_cooldown: float = 0.0


func _ready() -> void:
	EventBus.player_shoot.connect(_on_player_shoot)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta


func _on_player_shoot() -> void:
	if _shoot_cooldown > 0.0:
		return
	_shoot_cooldown = SHOOT_COOLDOWN_TIME
	_play_beep(_sfx_shoot, 880.0, 0.05)


func _on_enemy_destroyed(_score: int, _pos: Vector2) -> void:
	_play_beep(_sfx_enemy_death, 440.0, 0.10)


func _on_player_died() -> void:
	_play_beep(_sfx_player_death, 220.0, 0.25)


func _play_beep(stream_player: AudioStreamPlayer, freq: float, duration: float) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = duration + 0.05
	stream_player.stream = gen
	stream_player.play()
	var pb: AudioStreamGeneratorPlayback = stream_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var sample_count: int = int(MIX_RATE * duration)
	var buffer := PackedVector2Array()
	buffer.resize(sample_count)
	for i: int in sample_count:
		var t: float = float(i) / MIX_RATE
		var sample: float = sin(TAU * freq * t) * 0.25
		buffer[i] = Vector2(sample, sample)
	if pb.can_push_buffer(sample_count):
		pb.push_buffer(buffer)
