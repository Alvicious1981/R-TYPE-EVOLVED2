class_name SfxPlayer extends Node

## Procedural SFX synthesis via AudioStreamWAV (PCM 16-bit, 22050 Hz).
## All waveforms are generated in _ready() and cached — zero runtime allocation.

const MIX_RATE: int = 22050
const SHOOT_COOLDOWN_TIME: float = 0.15

@onready var _sfx_shoot: AudioStreamPlayer = $SFX_Shoot
@onready var _sfx_enemy_death: AudioStreamPlayer = $SFX_EnemyDeath
@onready var _sfx_player_death: AudioStreamPlayer = $SFX_PlayerDeath
@onready var _sfx_wave_charge: AudioStreamPlayer = $SFX_WaveCharge

var _shoot_cooldown: float = 0.0


func _ready() -> void:
	_sfx_shoot.stream       = _gen_laser()
	_sfx_enemy_death.stream = _gen_explosion(0.35, 42)
	_sfx_player_death.stream = _gen_explosion(0.55, 99)
	_sfx_wave_charge.stream = _gen_wave_charge()

	EventBus.player_shoot.connect(_on_player_shoot)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.wave_charge_started.connect(_on_wave_charge_started)
	EventBus.wave_charge_changed.connect(_on_wave_charge_changed)


func _process(delta: float) -> void:
	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta


func _on_player_shoot() -> void:
	if _shoot_cooldown > 0.0:
		return
	_shoot_cooldown = SHOOT_COOLDOWN_TIME
	_sfx_shoot.play()


func _on_enemy_destroyed(_score: int, _pos: Vector2) -> void:
	_sfx_enemy_death.play()


func _on_player_died() -> void:
	_sfx_player_death.play()


func _on_wave_charge_started() -> void:
	_sfx_wave_charge.play()


func _on_wave_charge_changed(_level: int) -> void:
	_sfx_wave_charge.play()


# ---------------------------------------------------------------------------
# PCM helpers
# ---------------------------------------------------------------------------

## Converts a normalised [-1.0, 1.0] float array to a 16-bit mono AudioStreamWAV.
static func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		var s: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		bytes[i * 2]     = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	wav.data = bytes
	return wav


# ---------------------------------------------------------------------------
# Waveform generators
# ---------------------------------------------------------------------------

## Laser: square wave with exponential downward pitch bend (880 Hz → 110 Hz, 0.12 s).
## freq(t) = 880 * (110/880)^norm  — smooth logarithmic sweep.
static func _gen_laser() -> AudioStreamWAV:
	const DURATION: float  = 0.12
	const FREQ_START: float = 880.0
	const FREQ_END: float   = 110.0
	var n: int = int(MIX_RATE * DURATION)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase: float = 0.0
	for i: int in n:
		var norm: float = float(i) / float(n)
		var freq: float = FREQ_START * pow(FREQ_END / FREQ_START, norm)
		phase += TAU * freq / float(MIX_RATE)
		var sq: float = 1.0 if fmod(phase, TAU) < PI else -1.0
		s[i] = sq * (1.0 - norm * 0.4) * 0.70
	return _make_wav(s)


## Explosion: white noise × exponential decay envelope  exp(-5 * norm).
## seed param keeps enemy and player-death timbres distinct.
static func _gen_explosion(duration: float, seed: int) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * duration)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i: int in n:
		var norm: float = float(i) / float(n)
		var amp: float  = exp(-5.0 * norm)
		s[i] = rng.randf_range(-1.0, 1.0) * amp * 0.85
	return _make_wav(s)


## Wave Charge: sine frequency sweep 200 Hz → 1400 Hz with sin(norm·π) envelope.
## Linear sweep gives a clear "charging up" percept.
static func _gen_wave_charge() -> AudioStreamWAV:
	const DURATION: float   = 0.28
	const FREQ_START: float = 200.0
	const FREQ_END: float   = 1400.0
	var n: int = int(MIX_RATE * DURATION)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase: float = 0.0
	for i: int in n:
		var norm: float = float(i) / float(n)
		var freq: float = FREQ_START + (FREQ_END - FREQ_START) * norm
		phase += TAU * freq / float(MIX_RATE)
		var env: float = sin(norm * PI)
		s[i] = sin(phase) * env * 0.65
	return _make_wav(s)
