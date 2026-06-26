extends CanvasLayer

## ShaderManager — darkness overlay and TV-static transition effects.
## The PS2 post-processing shader (grain, scanlines, chromatic aberration)
## lives on the SubViewportContainer in main.gd / main.tscn.

@onready var darkness: ColorRect = $DarknessRect
@onready var static_overlay: ColorRect = $StaticRect

## Set externally by main.gd after it creates the SubViewportContainer material.
var ps2_material: ShaderMaterial = null

var darkness_material: ShaderMaterial = null
var static_material: ShaderMaterial = null

var glitch_timer: float = 0.0
var glitch_interval: float = 8.0

func _ready() -> void:
	# Darkness overlay — breathing vignette shader
	darkness_material = ShaderMaterial.new()
	darkness_material.shader = load("res://shaders/darkness_overlay.gdshader")
	darkness_material.set_shader_parameter("darkness", 0.55)
	darkness.material = darkness_material
	
	# TV static — used for transitions and jump moments
	static_material = ShaderMaterial.new()
	static_material.shader = load("res://shaders/static_noise.gdshader")
	static_overlay.material = static_material
	static_overlay.visible = false
	static_overlay.modulate.a = 0.0
	
	glitch_interval = randf_range(5.0, 15.0)

func _process(delta: float) -> void:
	var t: float = GameManager.game_time
	if darkness_material:
		darkness_material.set_shader_parameter("time_val", t)
	if static_material:
		static_material.set_shader_parameter("time_val", t)
	
	# Random VHS tracking glitches via ps2_material (set by main.gd)
	glitch_timer += delta
	if glitch_timer >= glitch_interval:
		glitch_timer = 0.0
		glitch_interval = randf_range(6.0, 20.0)
		var dur := randf_range(0.05, 0.35)
		_trigger_glitch(dur)

func _trigger_glitch(duration: float) -> void:
	if ps2_material:
		ps2_material.set_shader_parameter("tracking_glitch", randf_range(0.3, 1.0))
		await get_tree().create_timer(duration).timeout
		ps2_material.set_shader_parameter("tracking_glitch", 0.0)

func flash_static(duration: float = 0.6) -> void:
	static_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(static_overlay, "modulate:a", 1.0, 0.08)
	tween.tween_interval(duration * 0.5)
	tween.tween_property(static_overlay, "modulate:a", 0.0, duration * 0.5)
	await tween.finished
	static_overlay.visible = false

func set_darkness(value: float) -> void:
	if darkness_material:
		darkness_material.set_shader_parameter("darkness", value)

func fade_to_black(duration: float = 1.0) -> void:
	var current: float = 0.55
	if darkness_material:
		var v = darkness_material.get_shader_parameter("darkness")
		if v != null:
			current = float(v)
	var tween := create_tween()
	tween.tween_method(set_darkness, current, 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_method(set_darkness, 1.0, 0.55, duration)
	await tween.finished
