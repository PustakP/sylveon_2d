extends Node

## GameManager — global singleton
## Tracks game state, current room, persistent flags

signal room_changed(room_id: String)
signal event_triggered(event_id: String)

enum GameState {
	IDLE,
	TRANSITIONING,
	DIALOGUE,
	GAME_OVER,
}

var state: GameState = GameState.IDLE
var current_room: String = "corridor"
var visited_rooms: Dictionary = {}
var flags: Dictionary = {
	"saw_figure": false,
	"found_key": false,
	"opened_door": false,
	"heard_sound": false,
	"entered_staircase": false,
	"reached_end": false,
}

# Persistent time counter for shaders
var game_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	game_time += delta

func set_flag(flag: String, value: bool = true) -> void:
	if flag in flags:
		flags[flag] = value

func get_flag(flag: String) -> bool:
	if flag in flags:
		return flags[flag]
	return false

func change_room(room_id: String) -> void:
	if state == GameState.TRANSITIONING:
		return
	visited_rooms[current_room] = true
	current_room = room_id
	room_changed.emit(room_id)

func trigger_event(event_id: String) -> void:
	event_triggered.emit(event_id)
