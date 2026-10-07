shader_type canvas_item;

// Pixelation: number of "pixels" across the rect. Lower = chunkier.
uniform float resolution : hint_range(8.0, 512.0, 1.0) = 64.0;
// How fast the lines travel toward the center. Negative = outward.
uniform float speed : hint_range(-5.0, 5.0) = 0.5;
// How many lines are visible between the edge and the center.
uniform float line_frequency : hint_range(1.0, 32.0) = 6.0;
// How much the lines bunch up toward the middle. 1 = evenly spaced, lower = tighter in the center.
uniform float center_bunching : hint_range(0.1, 1.0) = 0.5;
// Thickness of each line as a fraction of the gap between lines.
uniform float line_width : hint_range(0.0, 1.0) = 0.25;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Snap UVs to a grid for the resolution control
	vec2 uv = (floor(UV * resolution) + 0.5) / resolution;

	// r = 0 at center, 1 at the edge of the circle
	float r = length(uv - vec2(0.5)) * 2.0;

	// Warp the radius so rings get closer together near the center
	float warped = pow(r, center_bunching);

	// Concentric lines moving in
	float phase = fract(warped * line_frequency + TIME * speed);
	float line = step(phase, line_width);

	// Round mask
	float mask = step(r, 1.0);

	// Only the lines are drawn; everything else is transparent
	COLOR = vec4(line_color.rgb, line_color.a * line * mask * alpha);
}
