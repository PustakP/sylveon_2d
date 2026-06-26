extends Node2D

## Room: Staircase — descending into deeper darkness

signal interaction_available(text: String, action: Callable)
signal interaction_ended()
signal room_transition_requested(room_id: String)
signal show_message(text: String, duration: float)
signal play_sound(sound_name: String)

@onready var background: TextureRect = $Background
@onready var back_zone: Area2D = $BackZone
@onready var descend_zone: Area2D = $DescendZone
@onready var event_timer: Timer = $EventTimer

var can_interact: bool = true
var descent_count: int = 0

func _ready() -> void:
	back_zone.mouse_entered.connect(_on_back_hover)
	back_zone.mouse_exited.connect(_on_exit_zone)
	back_zone.input_event.connect(_on_back_click)
	
	descend_zone.mouse_entered.connect(_on_descend_hover)
	descend_zone.mouse_exited.connect(_on_exit_zone)
	descend_zone.input_event.connect(_on_descend_click)
	
	event_timer.timeout.connect(_random_event)
	event_timer.start(randf_range(6.0, 12.0))

func on_enter() -> void:
	GameManager.set_flag("entered_staircase")
	play_sound.emit("heartbeat")
	await get_tree().create_timer(1.5).timeout
	show_message.emit("stairs descend into nothing.", 3.5)
	await get_tree().create_timer(5.0).timeout
	show_message.emit("you can hear your own breathing.", 3.0)

func on_exit() -> void:
	event_timer.stop()

func _random_event() -> void:
	play_sound.emit("creak")
	var shader_mgr = get_node_or_null("/root/ShaderManager")
	if shader_mgr:
		shader_mgr.flash_static(0.2)
	event_timer.start(randf_range(8.0, 18.0))

func _on_back_hover() -> void:
	if not can_interact: return
	interaction_available.emit("[ go back up ]", _go_back)

func _on_exit_zone() -> void:
	interaction_ended.emit()

func _on_back_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_go_back()

func _go_back() -> void:
	if not can_interact: return
	can_interact = false
	interaction_ended.emit()
	show_message.emit("you can't go back.", 3.0)
	await get_tree().create_timer(2.0).timeout
	show_message.emit("there is no back.", 3.0)
	await get_tree().create_timer(2.5).timeout
	can_interact = true

func _on_descend_hover() -> void:
	if not can_interact: return
	interaction_available.emit("[ descend ]", _descend)

func _on_descend_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_descend()

func _descend() -> void:
	if not can_interact: return
	can_interact = false
	interaction_ended.emit()
	descent_count += 1
	
	if descent_count == 1:
		play_sound.emit("static")
		show_message.emit("each step is heavier than the last.", 3.5)
		await get_tree().create_timer(4.0).timeout
		can_interact = true
	elif descent_count == 2:
		play_sound.emit("heartbeat")
		show_message.emit("the air gets thicker.", 3.0)
		await get_tree().create_timer(4.0).timeout
		can_interact = true
	else:
		# Third time: commit to the end
		show_message.emit("you keep going.", 2.5)
		await get_tree().create_timer(2.5).timeout
		room_transition_requested.emit("ending")
