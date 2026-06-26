extends Node

## SoundManager — fully procedural audio synthesis, no audio files needed.

var audio_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer = null
var _ambient_phase: float = 0.0

func _ready() -> void:
	# SFX player pool
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		p.bus = "Master"
		audio_players.append(p)
	# Dedicated ambient channel
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	ambient_player.bus = "Master"
	_start_ambient()

func _start_ambient() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.5
	ambient_player.stream = gen
	ambient_player.volume_db = -8.0
	ambient_player.play()

func _process(_delta: float) -> void:
	if ambient_player and ambient_player.playing:
		_fill_ambient_buffer()

func _fill_ambient_buffer() -> void:
	var playback := ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	var frames := playback.get_frames_available()
	if frames <= 0:
		return
	var sr := 22050.0
	var data := PackedVector2Array()
	data.resize(frames)
	for i in range(frames):
		var t := _ambient_phase + float(i) / sr
		# Layered horror drone: 28 / 40 / 55 / 82 Hz
		var drone := sin(TAU * 28.0 * t) * 0.12
		drone += sin(TAU * 40.0 * t) * 0.30
		drone += sin(TAU * 55.0 * t + 0.3) * 0.15
		drone += sin(TAU * 82.5 * t + 0.7) * 0.08
		# Slow organic modulation
		var m1 := sin(TAU * 0.07 * t) * 0.5 + 0.5
		var m2 := sin(TAU * 0.13 * t + 1.2) * 0.3 + 0.7
		drone *= (0.5 + m1 * 0.3) * (0.7 + m2 * 0.3)
		# Subtle noise floor
		drone += randf_range(-1.0, 1.0) * 0.012
		var s := clamp(drone, -1.0, 1.0)
		data[i] = Vector2(s, s)
	_ambient_phase += float(frames) / sr
	if _ambient_phase > 10000.0:
		_ambient_phase = fmod(_ambient_phase, 100.0)
	playback.push_buffer(data)

# ---- Public API ----

func play_heartbeat() -> void:   _play_sound("heartbeat", -4.0)
func play_creak() -> void:       _play_sound("creak",     -6.0)
func play_static_burst() -> void:_play_sound("static",    -2.0)
func play_breath() -> void:      _play_sound("breath",    -8.0)
func play_stinger() -> void:     _play_sound("stinger",   -3.0)

func _get_free_player() -> AudioStreamPlayer:
	for p in audio_players:
		if not p.playing:
			return p
	return audio_players[0]

func _play_sound(type: String, vol_db: float) -> void:
	var player := _get_free_player()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 1.5
	player.stream = gen
	player.volume_db = vol_db
	player.play()
	# Defer buffer fill so the playback object is ready
	_fill_sfx_buffer.call_deferred(player, type)

func _fill_sfx_buffer(player: AudioStreamPlayer, type: String) -> void:
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	var sr := 22050.0
	var frames := int(sr * 1.0)
	var data := PackedVector2Array()
	data.resize(frames)
	match type:
		"heartbeat":
			for i in range(frames):
				var t := float(i) / sr
				var b1 := exp(-t * 15.0) * sin(TAU * 60.0 * t) * 0.8 if t < 0.08 else 0.0
				var b2 := 0.0
				if t > 0.15 and t < 0.28:
					var t2 := t - 0.15
					b2 = exp(-t2 * 20.0) * sin(TAU * 55.0 * t2) * 0.6
				var s := clamp(b1 + b2, -1.0, 1.0)
				data[i] = Vector2(s, s)
		"creak":
			for i in range(frames):
				var t := float(i) / sr
				if t > 0.5:
					break
				var env := exp(-t * 4.0) * (1.0 - exp(-t * 30.0))
				var s := env * sin(TAU * (180.0 - t * 120.0) * t + sin(TAU * 2.0 * t) * 3.0)
				s += randf_range(-0.1, 0.1) * env
				data[i] = Vector2(clamp(s, -1.0, 1.0), clamp(s, -1.0, 1.0))
		"static":
			for i in range(frames):
				var t := float(i) / sr
				var env := (1.0 - exp(-t * 30.0)) * exp(-t * 5.0)
				var s := randf_range(-1.0, 1.0) * env
				data[i] = Vector2(s, s)
		"breath":
			for i in range(frames):
				var t := float(i) / sr
				var env := sin(PI * t) * 0.5
				var s := randf_range(-1.0, 1.0) * 0.08 * env
				s += sin(TAU * 220.0 * t) * 0.02 * env
				data[i] = Vector2(s, s)
		"stinger":
			for i in range(frames):
				var t := float(i) / sr
				var env := exp(-t * 8.0)
				var freq := 800.0 - t * 500.0
				var s := env * (sin(TAU * freq * t) * 0.4
							  + sin(TAU * freq * 1.5 * t) * 0.3
							  + randf_range(-0.3, 0.3) * 0.3)
				data[i] = Vector2(clamp(s, -1.0, 1.0), clamp(s, -1.0, 1.0))
	playback.push_buffer(data)
