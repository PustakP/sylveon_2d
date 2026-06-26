extends Node2D

## Room: Side Room — dark room with a key item

signal interaction_available(text: String, action: Callable)
signal interaction_ended()
signal room_transition_requested(room_id: String)
signal show_message(text: String, duration: float)
signal play_sound(sound_name: String)

@onready var background: TextureRect = $Background
@onready var key_object: TextureRect = $KeyObject
@onready var back_zone: Area2D = $BackZone
@onready var key_zone: Area2D = $KeyZone
@onready var breath_timer: Timer = $BreathTimer

var key_taken: bool = false
var can_interact: bool = true

func _ready() -> void:
	key_object.visible = not GameManager.get_flag("found_key")
	key_taken = GameManager.get_flag("found_key")
	
	back_zone.mouse_entered.connect(_on_back_hover)
	back_zone.mouse_exited.connect(_on_back_exit)
	back_zone.input_event.connect(_on_back_click)
	
	key_zone.mouse_entered.connect(_on_key_hover)
	key_zone.mouse_exited.connect(_on_key_exit)
	key_zone.input_event.connect(_on_key_click)
	
	breath_timer.timeout.connect(_on_breath)
	breath_timer.start(randf_range(5.0, 12.0))

func on_enter() -> void:
	play_sound.emit("static")
	await get_tree().create_timer(1.0).timeout
	show_message.emit("the walls are wet.", 3.0)
	
	if not key_taken:
		await get_tree().create_timer(4.0).timeout
		show_message.emit("something catches your eye.", 2.5)

func on_exit() -> void:
	pass

func _process(_delta: float) -> void:
	# Subtle key pulse if present
	if not key_taken and key_object.visible:
		var p = sin(GameManager.game_time * 2.0) * 0.08 + 0.92
		key_object.modulate = Color(p, p * 0.85, p * 0.7, 1.0)

func _on_breath() -> void:
	play_sound.emit("breath")
	breath_timer.start(randf_range(8.0, 20.0))

func _on_key_hover() -> void:
	if key_taken or not can_interact: return
	interaction_available.emit("[ pick up ]", _take_key)

func _on_key_exit() -> void:
	interaction_ended.emit()

func _on_key_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_take_key()

func _take_key() -> void:
	if key_taken or not can_interact: return
	can_interact = false
	interaction_ended.emit()
	
	play_sound.emit("creak")
	GameManager.set_flag("found_key")
	key_taken = true
	
	var tween = create_tween()
	tween.tween_property(key_object, "modulate:a", 0.0, 0.5)
	await tween.finished
	key_object.visible = false
	
	show_message.emit("you have it now.", 3.0)
	await get_tree().create_timer(4.0).timeout
	show_message.emit("go back.", 2.5)
	await get_tree().create_timer(2.0).timeout
	can_interact = true

func _on_back_hover() -> void:
	if not can_interact: return
	interaction_available.emit("[ return to corridor ]", _go_back)

func _on_back_exit() -> void:
	interaction_ended.emit()

func _on_back_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_go_back()

func _go_back() -> void:
	if not can_interact: return
	can_interact = false
	interaction_ended.emit()
	room_transition_requested.emit("corridor")
