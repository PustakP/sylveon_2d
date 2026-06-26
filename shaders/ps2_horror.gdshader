shader_type canvas_item;

// PS2-style horror post-processing shader
// Simulates: scanlines, grain, chromatic aberration, vignette,
// phosphor glow, signal noise, and VHS tracking errors

uniform float time_val : hint_range(0.0, 9999.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.85;
uniform float chromatic_strength : hint_range(0.0, 0.02) = 0.006;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.08;
uniform float flicker_speed : hint_range(0.0, 10.0) = 3.0;
uniform float contrast : hint_range(0.5, 3.0) = 1.35;
uniform float brightness : hint_range(0.0, 1.0) = 0.75;
uniform vec4 tint_color : source_color = vec4(0.05, 0.12, 0.08, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.25;
uniform float tracking_glitch : hint_range(0.0, 1.0) = 0.0;

// --- Noise helpers ---
float hash(vec2 p) {
	p = fract(p * vec2(443.8975, 397.2973));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	
	// --- VHS tracking error / horizontal shift ---
	float track_offset = 0.0;
	if (tracking_glitch > 0.01) {
		float band = step(0.97, sin(uv.y * 80.0 + time_val * 7.3));
		float band2 = step(0.994, sin(uv.y * 23.0 + time_val * 2.1));
		track_offset = (band * 0.012 + band2 * 0.004) * tracking_glitch;
		uv.x = fract(uv.x + track_offset);
	}
	
	// --- Chromatic aberration (split RGB channels) ---
	vec2 dir = uv - 0.5;
	float ca = chromatic_strength * (1.0 + length(dir) * 0.5);
	float r_val = texture(TEXTURE, uv - dir * ca).r;
	float g_val = texture(TEXTURE, uv).g;
	float b_val = texture(TEXTURE, uv + dir * ca).b;
	vec4 col = vec4(r_val, g_val, b_val, texture(TEXTURE, uv).a);
	
	// --- Scanlines ---
	float scanline = sin(uv.y * 600.0) * 0.5 + 0.5;
	scanline = pow(scanline, 0.8);
	float scanline_dark = 1.0 - scanline_strength * (1.0 - scanline);
	col.rgb *= scanline_dark;
	
	// --- Horizontal scan interference ---
	float h_scan = sin(uv.y * 1200.0 + time_val * 4.0) * 0.03 * scanline_strength;
	col.rgb += h_scan;
	
	// --- Film grain ---
	float t = floor(time_val * 24.0); // 24fps grain update
	float g = hash(uv * vec2(1280.0, 720.0) + t * 0.017);
	float g2 = hash(uv * vec2(640.0, 360.0) + t * 0.031 + 0.5);
	float grain = (g * 0.7 + g2 * 0.3) - 0.5;
	col.rgb += grain * grain_strength;
	
	// --- Signal noise bursts ---
	float n = noise(vec2(time_val * 5.0, uv.y * 40.0));
	float noise_band = step(0.96, n);
	col.rgb += noise_band * noise_strength * vec3(0.9, 1.0, 0.85);
	
	// --- Flicker ---
	float flicker = 1.0 - 0.04 * sin(time_val * flicker_speed * 6.28) 
					- 0.02 * sin(time_val * flicker_speed * 17.3 + 1.2);
	col.rgb *= flicker;
	
	// --- Contrast & brightness ---
	col.rgb = (col.rgb - 0.5) * contrast + 0.5;
	col.rgb *= brightness;
	
	// --- Greenish sickly tint ---
	col.rgb = mix(col.rgb, col.rgb * tint_color.rgb * 3.0, tint_strength);
	
	// --- Vignette ---
	float vd = length(UV - 0.5) * 1.8;
	vd = vd * vd;
	float vig = 1.0 - vd * vignette_strength;
	vig = clamp(vig, 0.0, 1.0);
	col.rgb *= vig;
	
	// --- Phosphor softness at edges ---
	float edge_soft = 1.0 - smoothstep(0.4, 0.5, length(UV - 0.5));
	col.rgb *= edge_soft * 0.15 + 0.85;
	
	// Clamp
	col.rgb = clamp(col.rgb, 0.0, 1.0);
	COLOR = col;
}
