extends Node2D

## Room: Corridor — first room the player sees
## Dark hospital corridor. A door to the side. A figure at the far end.

signal interaction_available(text: String, action: Callable)
signal interaction_ended()
signal room_transition_requested(room_id: String)
signal show_message(text: String, duration: float)
signal play_sound(sound_name: String)

@onready var background: TextureRect = $Background
@onready var figure: TextureRect = $Figure
@onready var door_zone: Area2D = $InteractionZones/DoorZone
@onready var forward_zone: Area2D = $InteractionZones/ForwardZone
@onready var figure_zone: Area2D = $InteractionZones/FigureZone
@onready var figure_flicker: Timer = $FigureFlicker

var figure_visible: bool = false
var figure_fade_phase: float = 0.0
var door_hovered: bool = false
var can_interact: bool = true

func _ready() -> void:
	figure.modulate.a = 0.0
	figure.visible = true
	
	# Connect zone signals (guard against missing nodes)
	if door_zone:
		door_zone.mouse_entered.connect(_on_door_hover)
		door_zone.mouse_exited.connect(_on_door_exit)
		door_zone.input_event.connect(_on_door_click)
	
	if forward_zone:
		forward_zone.mouse_entered.connect(_on_forward_hover)
		forward_zone.mouse_exited.connect(_on_forward_exit)
		forward_zone.input_event.connect(_on_forward_click)
	
	if figure_zone:
		figure_zone.mouse_entered.connect(_on_figure_hover)
		figure_zone.input_event.connect(_on_figure_click)
	
	if figure_flicker:
		figure_flicker.timeout.connect(_flicker_figure)
		figure_flicker.start(randf_range(3.0, 8.0))

func on_enter() -> void:
	await get_tree().create_timer(1.2).timeout
	show_message.emit("something brought you here.", 3.5)
	await get_tree().create_timer(4.5).timeout
	show_message.emit("you don't know what.", 3.0)
	
	# Schedule first figure appearance
	await get_tree().create_timer(8.0).timeout
	if not GameManager.get_flag("saw_figure"):
		_show_figure_briefly()

func on_exit() -> void:
	pass

func _process(delta: float) -> void:
	# Subtle figure breathing animation
	if figure_visible:
		figure_fade_phase += delta * 1.5
		figure.modulate.a = 0.45 + sin(figure_fade_phase) * 0.15

func _flicker_figure() -> void:
	if not figure_visible and GameManager.get_flag("saw_figure"):
		_show_figure_briefly()
	figure_flicker.start(randf_range(4.0, 14.0))

func _show_figure_briefly() -> void:
	figure_visible = true
	var tween = create_tween()
	tween.tween_property(figure, "modulate:a", 0.5, 0.15)
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	tween = create_tween()
	tween.tween_property(figure, "modulate:a", 0.0, 0.3)
	await tween.finished
	figure_visible = false
	
	if not GameManager.get_flag("saw_figure"):
		GameManager.set_flag("saw_figure")
		play_sound.emit("stinger")
		await get_tree().create_timer(0.5).timeout
		show_message.emit("there was something at the end of the hall.", 4.0)

func _on_door_hover() -> void:
	if not can_interact: return
	door_hovered = true
	interaction_available.emit("[ examine door ]", _use_door)

func _on_door_exit() -> void:
	door_hovered = false
	interaction_ended.emit()

func _on_door_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_use_door()

func _use_door() -> void:
	if not can_interact: return
	can_interact = false
	interaction_ended.emit()
	
	play_sound.emit("creak")
	await get_tree().create_timer(0.3).timeout
	show_message.emit("the door groans but doesn't move.", 3.0)
	await get_tree().create_timer(1.5).timeout
	
	if not GameManager.get_flag("found_key"):
		show_message.emit("locked.", 2.5)
		await get_tree().create_timer(2.0).timeout
		can_interact = true
	else:
		show_message.emit("it gives way.", 2.0)
		await get_tree().create_timer(1.0).timeout
		GameManager.set_flag("opened_door")
		room_transition_requested.emit("side_room")

func _on_forward_hover() -> void:
	if not can_interact: return
	interaction_available.emit("[ move forward ]", _move_forward)

func _on_forward_exit() -> void:
	interaction_ended.emit()

func _on_forward_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_forward()

func _move_forward() -> void:
	if not can_interact: return
	can_interact = false
	interaction_ended.emit()
	
	# If figure was seen, play heartbeat
	if GameManager.get_flag("saw_figure"):
		play_sound.emit("heartbeat")
		show_message.emit("your chest tightens.", 2.5)
		await get_tree().create_timer(3.0).timeout
		show_message.emit("you see stairs down.", 2.5)
		await get_tree().create_timer(2.0).timeout
		room_transition_requested.emit("staircase")
	else:
		show_message.emit("the corridor stretches endlessly ahead.", 3.0)
		await get_tree().create_timer(3.5).timeout
		_show_figure_briefly()
		await get_tree().create_timer(1.0).timeout
		can_interact = true

func _on_figure_hover() -> void:
	if figure.modulate.a > 0.1:
		interaction_available.emit("[ something is there ]", func(): pass)

func _on_figure_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if figure.modulate.a > 0.1:
			play_sound.emit("stinger")
			show_message.emit("it's looking at you.", 3.0)
			interaction_ended.emit()
