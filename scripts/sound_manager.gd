extends Node

## SoundManager — handles atmospheric audio generation via procedural noise
## Since we have no audio files, we synthesize short tones and noise bursts

var audio_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer = null
var current_ambient: AudioStreamGenerator = null

func _ready() -> void:
	# Create a pool of audio players for sound effects
	for i in range(4):
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.bus = "Master"
		audio_players.append(p)
	
	# Dedicated ambient player
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	ambient_player.bus = "Master"
	
	# Start ambient drone
	_start_ambient()

func _start_ambient() -> void:
	# Create a looping generator stream for ambient drone
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.5
	current_ambient = gen
	ambient_player.stream = gen
	ambient_player.volume_db = -8.0
	ambient_player.play()

func _process(_delta: float) -> void:
	if ambient_player and ambient_player.playing:
		_fill_ambient_buffer()

var _ambient_phase: float = 0.0

func _fill_ambient_buffer() -> void:
	var playback = ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	
	var frames = playback.get_frames_available()
	if frames <= 0:
		return
	
	var sr = 22050.0
	_time_acc += float(frames) / sr
	
	# Low drone frequencies (horror ambience)
	var freq1 = 40.0   # deep rumble
	var freq2 = 55.0   # minor second above
	var freq3 = 82.5   # fifth
	
	var data = PackedVector2Array()
	data.resize(frames)
	
	for i in range(frames):
		var t = _ambient_phase + float(i) / sr
		
		# Layered sine waves for drone
		var drone = sin(TAU * freq1 * t) * 0.3
		drone += sin(TAU * freq2 * t + 0.3) * 0.15
		drone += sin(TAU * freq3 * t + 0.7) * 0.08
		
		# Sub-bass rumble
		drone += sin(TAU * 28.0 * t) * 0.12
		
		# Slow modulation (breathing quality)
		var mod = sin(TAU * 0.07 * t) * 0.5 + 0.5
		var mod2 = sin(TAU * 0.13 * t + 1.2) * 0.3 + 0.7
		drone *= (0.5 + mod * 0.3) * (0.7 + mod2 * 0.3)
		
		# Very subtle noise floor
		var noise_val = randf_range(-1.0, 1.0) * 0.015
		
		var sample = clamp(drone + noise_val, -1.0, 1.0)
		data[i] = Vector2(sample, sample)
	
	_ambient_phase += float(frames) / sr
	# Keep phase from growing too large
	if _ambient_phase > 10000.0:
		_ambient_phase = fmod(_ambient_phase, 100.0)
	
	playback.push_buffer(data)

func play_heartbeat() -> void:
	_play_synthesized_sound("heartbeat")

func play_creak() -> void:
	_play_synthesized_sound("creak")

func play_static_burst() -> void:
	_play_synthesized_sound("static")

func play_breath() -> void:
	_play_synthesized_sound("breath")

func play_stinger() -> void:
	_play_synthesized_sound("stinger")

func _get_free_player() -> AudioStreamPlayer:
	for p in audio_players:
		if not p.playing:
			return p
	return audio_players[0]

func _play_synthesized_sound(type: String) -> void:
	var player = _get_free_player()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 1.0
	player.stream = gen
	
	match type:
		"heartbeat":
			player.volume_db = -4.0
			_synthesize_heartbeat(gen)
		"creak":
			player.volume_db = -6.0
			_synthesize_creak(gen)
		"static":
			player.volume_db = -2.0
			_synthesize_static_burst(gen)
		"breath":
			player.volume_db = -8.0
			_synthesize_breath(gen)
		"stinger":
			player.volume_db = -3.0
			_synthesize_stinger(gen)
	
	player.play()
	# Fill the buffer after starting
	await get_tree().process_frame
	_fill_sfx_buffer(player, type)

func _fill_sfx_buffer(player: AudioStreamPlayer, type: String) -> void:
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	var sr = 22050.0
	var frames = int(sr * 1.0)
	var data = PackedVector2Array()
	data.resize(frames)
	
	match type:
		"heartbeat":
			for i in range(frames):
				var t = float(i) / sr
				var beat1 = exp(-t * 15.0) * sin(TAU * 60.0 * t) * 0.8 if t < 0.08 else 0.0
				var beat2 = 0.0
				if t > 0.15 and t < 0.28:
					var t2 = t - 0.15
					beat2 = exp(-t2 * 20.0) * sin(TAU * 55.0 * t2) * 0.6
				var s = clamp(beat1 + beat2, -1.0, 1.0)
				data[i] = Vector2(s, s)
		"creak":
			for i in range(frames):
				var t = float(i) / sr
				if t > 0.5: break
				var env = exp(-t * 4.0) * (1.0 - exp(-t * 30.0))
				var freq = 180.0 - t * 120.0
				var s = env * sin(TAU * freq * t + sin(TAU * 2.0 * t) * 3.0)
				s += randf_range(-0.1, 0.1) * env
				data[i] = Vector2(clamp(s, -1.0, 1.0), clamp(s, -1.0, 1.0))
		"static":
			for i in range(frames):
				var t = float(i) / sr
				var env = (1.0 - exp(-t * 30.0)) * exp(-t * 5.0)
				var s = randf_range(-1.0, 1.0) * env
				data[i] = Vector2(s, s)
		"breath":
			for i in range(frames):
				var t = float(i) / sr
				var env = sin(PI * t) * 0.5
				var s = randf_range(-1.0, 1.0) * 0.08 * env
				s += sin(TAU * 220.0 * t) * 0.02 * env
				data[i] = Vector2(s, s)
		"stinger":
			for i in range(frames):
				var t = float(i) / sr
				var env = exp(-t * 8.0)
				var freq = 800.0 - t * 500.0
				var s = env * (sin(TAU * freq * t) * 0.4 + 
							   sin(TAU * (freq * 1.5) * t) * 0.3 + 
							   randf_range(-0.3, 0.3) * 0.3)
				data[i] = Vector2(clamp(s, -1.0, 1.0), clamp(s, -1.0, 1.0))
	
	playback.push_buffer(data)

func _synthesize_heartbeat(_gen: AudioStreamGenerator) -> void:
	pass # buffer filled after play

func _synthesize_creak(_gen: AudioStreamGenerator) -> void:
	pass

func _synthesize_static_burst(_gen: AudioStreamGenerator) -> void:
	pass

func _synthesize_breath(_gen: AudioStreamGenerator) -> void:
	pass

func _synthesize_stinger(_gen: AudioStreamGenerator) -> void:
	pass
