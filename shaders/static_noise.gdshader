shader_type canvas_item;

// Static noise / TV static shader for transition screens

uniform float time_val : hint_range(0.0, 9999.0) = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float speed : hint_range(0.1, 20.0) = 8.0;

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = floor(time_val * speed);
	float r = rand(UV + t);
	float r2 = rand(UV * 1.3 + t + 0.1);
	
	// Scanline structure in static
	float scan = step(0.5, sin(UV.y * 500.0));
	float static_val = mix(r, r2, 0.4) * scan * 0.6 + r * 0.4;
	static_val *= intensity;
	
	// Slight green tint in static (old monitor)
	vec3 col = vec3(static_val * 0.7, static_val * 0.85, static_val * 0.65);
	
	// Fade edges
	float edge = 1.0 - smoothstep(0.42, 0.5, length(UV - 0.5));
	col *= edge;
	
	COLOR = vec4(col, static_val);
}
