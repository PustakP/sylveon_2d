extends Node2D

## Room: Ending — the terminal room. No way out.

signal interaction_available(text: String, action: Callable)
signal interaction_ended()
signal room_transition_requested(room_id: String)
signal show_message(text: String, duration: float)
signal play_sound(sound_name: String)

@onready var background: TextureRect = $Background
@onready var look_zone: Area2D = $InteractionZones/LookZone
@onready var sequence_timer: Timer = $SequenceTimer

var sequence_step: int = 0
var running: bool = false

func _ready() -> void:
	if look_zone:
		look_zone.mouse_entered.connect(_on_look_hover)
		look_zone.mouse_exited.connect(_on_look_exit)
		look_zone.input_event.connect(_on_look_click)
	
	if sequence_timer:
		sequence_timer.timeout.connect(_next_sequence)

func on_enter() -> void:
	GameManager.set_flag("reached_end")
	GameManager.state = GameManager.GameState.DIALOGUE
	running = true
	
	# Heighten all shader effects
	var shader_mgr = get_node_or_null("/root/ShaderManager")
	if shader_mgr:
		shader_mgr.ps2_material.set_shader_parameter("grain_strength", 0.55)
		shader_mgr.ps2_material.set_shader_parameter("vignette_strength", 0.95)
		shader_mgr.ps2_material.set_shader_parameter("tracking_glitch", 0.2)
		shader_mgr.darkness_material.set_shader_parameter("darkness", 0.7)
		shader_mgr.darkness_material.set_shader_parameter("pulse_strength", 0.15)
	
	play_sound.emit("heartbeat")
	await get_tree().create_timer(2.0).timeout
	_run_ending_sequence()

func on_exit() -> void:
	running = false

func _run_ending_sequence() -> void:
	var messages = [
		["you've reached the end.", 4.0],
		["there is nothing here.", 4.0],
		["there never was.", 4.5],
		[".", 2.0],
		["..", 2.0],
		["...", 2.5],
		["you are still here.", 4.5],
		["why are you still here.", 5.0],
		["", 3.0],
	]
	
	for msg in messages:
		if not running:
			return
		show_message.emit(msg[0], msg[1] - 0.5)
		if msg[0] != "":
			play_sound.emit("creak" if randf() > 0.5 else "breath")
		await get_tree().create_timer(msg[1]).timeout
	
	# Final moment — full static and dark
	play_sound.emit("stinger")
	var shader_mgr = get_node_or_null("/root/ShaderManager")
	if shader_mgr:
		shader_mgr.flash_static(1.5)
		await get_tree().create_timer(0.5).timeout
		shader_mgr.fade_to_black(2.0)
	
	await get_tree().create_timer(3.0).timeout
	
	# Show restart option
	GameManager.state = GameManager.GameState.IDLE
	show_message.emit("[ click to begin again ]", 999.0)
	
	look_zone.input_event.connect(_on_restart_click)

func _on_look_hover() -> void:
	pass # nothing to hover in ending

func _on_look_exit() -> void:
	pass

func _on_look_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	pass # overwritten after ending

func _on_restart_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Reset all flags and restart
		GameManager.flags = {
			"saw_figure": false,
			"found_key": false,
			"opened_door": false,
			"heard_sound": false,
			"entered_staircase": false,
			"reached_end": false,
		}
		GameManager.current_room = "corridor"
		room_transition_requested.emit("corridor")
