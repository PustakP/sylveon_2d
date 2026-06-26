extends CanvasLayer

## ShaderManager — manages the global post-processing overlay layer
## The PS2 horror shader is applied here via a full-screen ColorRect

@onready var overlay: ColorRect = $PostProcessRect
@onready var darkness: ColorRect = $DarknessRect
@onready var static_overlay: ColorRect = $StaticRect

var ps2_material: ShaderMaterial
var darkness_material: ShaderMaterial
var static_material: ShaderMaterial

# Tracking glitch timer
var glitch_timer: float = 0.0
var glitch_interval: float = 8.0
var glitch_duration: float = 0.0

func _ready() -> void:
	# PS2 post-process
	ps2_material = ShaderMaterial.new()
	ps2_material.shader = load("res://shaders/ps2_horror.gdshader")
	overlay.material = ps2_material
	
	# Darkness overlay
	darkness_material = ShaderMaterial.new()
	darkness_material.shader = load("res://shaders/darkness_overlay.gdshader")
	darkness.material = darkness_material
	
	# Static noise (hidden by default)
	static_material = ShaderMaterial.new()
	static_material.shader = load("res://shaders/static_noise.gdshader")
	static_overlay.material = static_material
	static_overlay.visible = false
	static_overlay.modulate.a = 0.0
	
	# Randomize first glitch
	glitch_interval = randf_range(5.0, 15.0)

func _process(delta: float) -> void:
	var t: float = GameManager.game_time
	
	# Feed time into all shaders
	ps2_material.set_shader_parameter("time_val", t)
	darkness_material.set_shader_parameter("time_val", t)
	static_material.set_shader_parameter("time_val", t)
	
	# Handle random VHS tracking glitches
	glitch_timer += delta
	if glitch_timer >= glitch_interval:
		glitch_timer = 0.0
		glitch_interval = randf_range(6.0, 20.0)
		glitch_duration = randf_range(0.05, 0.4)
		_trigger_glitch(glitch_duration)

func _trigger_glitch(duration: float) -> void:
	ps2_material.set_shader_parameter("tracking_glitch", randf_range(0.4, 1.0))
	await get_tree().create_timer(duration).timeout
	ps2_material.set_shader_parameter("tracking_glitch", 0.0)

func flash_static(duration: float = 0.6) -> void:
	static_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(static_overlay, "modulate:a", 1.0, 0.08)
	tween.tween_interval(duration * 0.5)
	tween.tween_property(static_overlay, "modulate:a", 0.0, duration * 0.5)
	await tween.finished
	static_overlay.visible = false

func set_darkness(value: float) -> void:
	darkness_material.set_shader_parameter("darkness", value)

func fade_to_black(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.tween_method(set_darkness, darkness_material.get_shader_parameter("darkness"), 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.tween_method(set_darkness, 1.0, 0.55, duration)
	await tween.finished
