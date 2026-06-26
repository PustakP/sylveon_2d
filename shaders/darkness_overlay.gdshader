shader_type canvas_item;

// Darkness overlay shader — creeping shadow that breathes and pulses
// Used as a top-layer atmospheric darkness

uniform float time_val : hint_range(0.0, 9999.0) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.6;
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.4;
uniform float pulse_strength : hint_range(0.0, 0.3) = 0.08;

float hash(vec2 p) {
	p = fract(p * vec2(443.8975, 397.2973));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * (hash(p) * 2.0 - 1.0);
		p = p * 2.1 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	
	// Animate slow drifting noise for organic darkness
	float t = time_val * pulse_speed;
	float n = fbm(uv * 3.0 + vec2(t * 0.3, t * 0.17));
	float n2 = fbm(uv * 5.0 + vec2(-t * 0.21, t * 0.35) + 10.5);
	
	// Vignette base
	float d = length(uv - 0.5) * 2.0;
	float vignette = smoothstep(0.3, 1.2, d);
	
	// Breathing pulse
	float pulse = sin(time_val * pulse_speed * 6.28) * pulse_strength;
	
	// Combine
	float shadow = clamp(darkness + vignette * 0.5 + n * 0.08 + n2 * 0.05 + pulse, 0.0, 1.0);
	
	// Output black with variable alpha
	COLOR = vec4(0.0, 0.0, 0.0, shadow);
}
