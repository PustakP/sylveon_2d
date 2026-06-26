extends Node2D

## RoomBase — base class for all room scenes
## Each room scene should extend this or connect to these patterns

signal interaction_available(text: String, action_callback: Callable)
signal interaction_ended()

@onready var background: TextureRect = $Background
@onready var interaction_zones: Node2D = $InteractionZones if has_node("InteractionZones") else null

var current_hover_zone: Area2D = null

func _ready() -> void:
	pass

func get_room_id() -> String:
	return "base"

func on_enter() -> void:
	pass

func on_exit() -> void:
	pass
