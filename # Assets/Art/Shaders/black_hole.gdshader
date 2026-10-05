shader_type canvas_item;

// Put this on a square ColorRect / Sprite2D. Everything is driven by UV,
// so the effect scales with the node and fades out before the quad's edge.

const int AA = 2;      // supersampling per axis (1 = off, cheaper)
const int STEPS = 10;  // raymarch steps from the original shader

uniform float speed = 1.0;
uniform float hole_radius : hint_range(0.0, 0.9) = 0.22;     // event horizon size (0..1 of quad radius)
uniform float hole_softness : hint_range(0.001, 0.3) = 0.04; // soft edge of the horizon
uniform float lensing : hint_range(0.0, 1.0) = 0.6;          // how hard the image bends around the hole
uniform float rim_glow : hint_range(0.0, 8.0) = 2.0;         // extra brightness hugging the horizon
uniform float alpha_power : hint_range(0.1, 8.0) = 1.5;      // higher = alpha concentrates near the centre
uniform float alpha_boost : hint_range(0.0, 4.0) = 1.0;      // overall alpha multiplier
uniform float brightness : hint_range(0.0, 4.0) = 1.0;
uniform float colour_alpha : hint_range(0.0, 1.0) = 1.0;     // 0 = uniform alpha, 1 = alpha fully follows colour brightness
uniform float alpha_low : hint_range(0.0, 1.0) = 0.05;       // brightness at/below this is fully transparent
uniform float alpha_high : hint_range(0.0, 2.0) = 0.6;       // brightness at/above this is fully opaque

// 2D rotation
vec2 rot(vec2 v, float t) {
	float s = sin(t), c = cos(t);
	return mat2(vec2(c, -s), vec2(s, c)) * v;
}

// ACES tonemap: https://www.shadertoy.com/view/Xc3yzM
vec3 aces(vec3 c) {
	mat3 m1 = mat3(
		vec3(0.59719, 0.07600, 0.02840),
		vec3(0.35458, 0.90834, 0.13383),
		vec3(0.04823, 0.01566, 0.83777));
	mat3 m2 = mat3(
		vec3(1.60475, -0.10208, -0.00327),
		vec3(-0.53108, 1.10813, -0.07276),
		vec3(-0.07367, -0.00605, 1.07602));
	vec3 v = m1 * c;
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return m2 * (a / b);
}

// Xor's Dot Noise: https://www.shadertoy.com/view/wfsyRX
float dot_noise(vec3 p) {
	const float PHI = 1.618033988;
	const mat3 GOLD = mat3(
		vec3(-0.571464913, 0.814921382, 0.096597072),
		vec3(-0.278044873, -0.303026659, 0.911518454),
		vec3(0.772087367, 0.494042493, 0.399753815));
	return dot(cos(GOLD * p), sin(PHI * p * GOLD));
}

// The original effect. c is centred coords in -1..1.
vec3 nebula(vec2 c, float t) {
	vec3 p = vec3(0.0, 0.0, -1.0 - 0.5 * sin(t * 0.1));
	vec3 l = vec3(0.0);
	vec3 d = normalize(vec3(c, 1.0));
	for (int i = 0; i < STEPS; i++) {
		vec3 b = p;
		b.xy = rot(sin(b.xy * 0.25), t * 0.5 + b.z * 2.0);
		float s = 0.001 + abs(dot_noise(b * 20.0) / 20.0 - dot_noise(b)) * 0.7;
		s += abs(p.y * 0.2 + sin(p.z * 2.0 + abs(p.x) * 0.5)) * 0.5;
		p += d * s;
		l += (1.0 + 1.5 * sin(float(i) + length(p.xy * 0.1) + 2.0 + vec3(3.0, 1.5, 0.5))) / s;
	}
	return aces(l * l / 5e2);
}

void fragment() {
	float t = TIME * speed;
	vec2 px = fwidth(UV); // size of one pixel in UV space, for AA offsets

	vec3 col = vec3(0.0);
	for (int m = 0; m < AA; m++) {
		for (int n = 0; n < AA; n++) {
			vec2 off = (vec2(float(m), float(n)) + 0.5) / float(AA) - 0.5;
			vec2 c = (UV + off * px) * 2.0 - 1.0;
			c.y = -c.y; // Godot UV is y-down, Shadertoy is y-up

			// Gravitational lensing: pull the sampled image in toward the horizon
			float r2 = max(dot(c, c), 1e-4);
			c *= 1.0 - lensing * hole_radius * hole_radius / r2;

			col += nebula(c, t);
		}
	}
	col = max(col / float(AA * AA), vec3(0.0)) * brightness;

	float r = length(UV * 2.0 - 1.0); // 0 at centre, 1 at quad edge

	// Bright ring hugging the horizon
	col *= 1.0 + rim_glow * exp(-max(r - hole_radius, 0.0) * 12.0);

	// Black hole: fade colour to black inside the horizon
	float outside = smoothstep(hole_radius, hole_radius + hole_softness, r);

	// Per-colour alpha: bright streaks are opaque, dark gaps become see-through
	float lum = max(col.r, max(col.g, col.b));
	float colour_a = smoothstep(alpha_low, alpha_high, lum);

	col *= outside;

	// Radial alpha: 0 at the quad's edge, rising toward the centre
	float k = clamp((r - hole_radius) / (1.0 - hole_radius), 0.0, 1.0);
	float alpha = pow(1.0 - k, alpha_power) * alpha_boost;
	alpha *= mix(1.0, colour_a, colour_alpha);

	// Keep the hole itself opaque black
	alpha = clamp(max(alpha, 1.0 - outside), 0.0, 1.0);

	COLOR = vec4(col, alpha);
}
