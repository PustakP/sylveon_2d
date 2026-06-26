extends Node2D

## Main — root of the game, orchestrates room transitions and global UI

@onready var room_container: Node2D = $RoomContainer
var ui_layer: CanvasLayer = null
var prompt_label: Label = null
var message_label: RichTextLabel = null
var cursor_dot: Panel = null

# Scene map: room_id → scene path
const ROOM_SCENES: Dictionary = {
	"corridor": "res://scenes/room_corridor.tscn",
	"side_room": "res://scenes/room_side.tscn",
	"staircase": "res://scenes/room_staircase.tscn",
	"ending": "res://scenes/room_ending.tscn",
}

var current_room_node: Node2D = null
var is_transitioning: bool = false
var interaction_cooldown: float = 0.0

# Dialogue queue system
var dialogue_queue: Array[String] = []
var showing_dialogue: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# CanvasLayer children don't resolve via $ from Node2D — use get_node explicitly
	ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		prompt_label = ui_layer.get_node_or_null("PromptLabel")
		message_label = ui_layer.get_node_or_null("MessageLabel")
		cursor_dot = ui_layer.get_node_or_null("CursorDot")
	
	_setup_ui()
	
	# Connect to GameManager signals
	GameManager.room_changed.connect(_on_room_changed)
	GameManager.event_triggered.connect(_on_event_triggered)
	
	# Load starting room
	await get_tree().process_frame
	_load_room("corridor")

func _setup_ui() -> void:
	if prompt_label:
		prompt_label.text = ""
		prompt_label.modulate = Color(0.7, 0.85, 0.7, 0.0)
	if message_label:
		message_label.text = ""
		message_label.modulate = Color(0.7, 0.85, 0.7, 0.0)
	if cursor_dot:
		cursor_dot.modulate = Color(0.6, 0.9, 0.6, 0.7)

func _process(delta: float) -> void:
	# Update custom cursor
	if cursor_dot:
		cursor_dot.position = get_viewport().get_mouse_position() - Vector2(4, 4)
		var pulse = sin(GameManager.game_time * 4.0) * 0.15 + 0.85
		cursor_dot.modulate.a = pulse * 0.7
	
	# Decay interaction prompt if no longer hovering
	if interaction_cooldown > 0.0:
		interaction_cooldown -= delta

func _load_room(room_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	GameManager.state = GameManager.GameState.TRANSITIONING
	
	# Fade out + static
	var shader_mgr = get_node_or_null("/root/ShaderManager")
	if shader_mgr:
		shader_mgr.fade_to_black(0.5)
	
	await get_tree().create_timer(0.5).timeout
	
	# Unload old room
	if current_room_node:
		if current_room_node.has_method("on_exit"):
			current_room_node.on_exit()
		current_room_node.queue_free()
		current_room_node = null
	
	await get_tree().process_frame
	
	# Load new room
	if room_id in ROOM_SCENES:
		var scene = load(ROOM_SCENES[room_id]) as PackedScene
		if scene:
			current_room_node = scene.instantiate()
			room_container.add_child(current_room_node)
			
			# Connect room signals
			if current_room_node.has_signal("interaction_available"):
				current_room_node.interaction_available.connect(_show_prompt)
			if current_room_node.has_signal("interaction_ended"):
				current_room_node.interaction_ended.connect(_hide_prompt)
			if current_room_node.has_signal("room_transition_requested"):
				current_room_node.room_transition_requested.connect(_load_room)
			if current_room_node.has_signal("show_message"):
				current_room_node.show_message.connect(show_message)
			if current_room_node.has_signal("play_sound"):
				current_room_node.play_sound.connect(_on_play_sound)
			
			if current_room_node.has_method("on_enter"):
				current_room_node.on_enter()
	
	# Fade in
	await get_tree().create_timer(0.2).timeout
	if shader_mgr:
		shader_mgr.fade_from_black(0.8)
	
	await get_tree().create_timer(0.8).timeout
	is_transitioning = false
	GameManager.state = GameManager.GameState.IDLE

func _on_room_changed(room_id: String) -> void:
	_load_room(room_id)

func _on_event_triggered(event_id: String) -> void:
	match event_id:
		"stinger":
			var snd = get_node_or_null("/root/SoundManager")
			if snd:
				snd.play_stinger()
		"static":
			var shader_mgr = get_node_or_null("/root/ShaderManager")
			if shader_mgr:
				shader_mgr.flash_static(0.3)

func _show_prompt(text: String, _action: Callable) -> void:
	if not prompt_label:
		return
	prompt_label.text = text
	var tween = create_tween()
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.3)

func _hide_prompt() -> void:
	if not prompt_label:
		return
	var tween = create_tween()
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.5)
	await tween.finished
	prompt_label.text = ""

func show_message(text: String, duration: float = 3.5) -> void:
	if not message_label:
		return
	if showing_dialogue:
		dialogue_queue.append(text)
		return
	showing_dialogue = true
	message_label.text = "[color=#7acc7a]" + text + "[/color]"
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(duration).timeout
	tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 0.8)
	await tween.finished
	message_label.text = ""
	showing_dialogue = false
	if dialogue_queue.size() > 0:
		var next = dialogue_queue.pop_front()
		show_message(next)

func _on_play_sound(sound_name: String) -> void:
	var snd = get_node_or_null("/root/SoundManager")
	if not snd:
		return
	match sound_name:
		"creak": snd.play_creak()
		"static": snd.play_static_burst()
		"heartbeat": snd.play_heartbeat()
		"breath": snd.play_breath()
		"stinger": snd.play_stinger()
