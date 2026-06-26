shader_type canvas_item;

// Item glow — subtle pulsing warm glow for interactive items
// Applied to the key object in the side room

uniform float time_val : hint_range(0.0, 9999.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.9, 0.75, 0.3, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.8;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Skip nearly transparent pixels
	if (tex.a < 0.05) {
		COLOR = tex;
		return;
	}
	
	// Pulsing brightness
	float pulse = sin(time_val * pulse_speed * TAU) * 0.15 + 0.85;
	
	// Edge glow — brighter at center, fades at edge
	vec2 center = UV - 0.5;
	float dist = length(center);
	float edge_glow = smoothstep(0.5, 0.1, dist) * glow_strength;
	
	// Mix glow color with texture
	vec3 glow = glow_color.rgb * edge_glow * pulse;
	vec3 final_col = tex.rgb + glow * 0.3;
	final_col *= pulse;
	
	COLOR = vec4(clamp(final_col, 0.0, 1.0), tex.a);
}
