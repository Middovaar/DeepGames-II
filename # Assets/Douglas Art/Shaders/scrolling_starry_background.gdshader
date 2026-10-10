shader_type canvas_item;

uniform vec2 stars_speed = vec2(0.0, 0.0);
uniform float stars_density: hint_range(0.0, 1.0, 0.001) = 1.0;

varying vec2 position;

// https://thebookofshaders.com/10/
float random(vec2 st) {
	float strpx = fract(dot(st.xy, vec2(12.9898, 78.233)) * sin(dot(st.xy, vec2(12.9898, 78.233))));
	float strpy = fract((dot(st.xy, vec2(-12.9898, -78.233))) * dot(st.xy, vec2(-120.9898, 78.233)));
	
	return modf(strpx, strpy);
}

// Called for every vertex the material is visible on.
void vertex() {
	position = VERTEX;
}

// Called for every pixel the material is visible on.
void fragment() {
	vec2 uv = (position + TIME * stars_speed) * TEXTURE_PIXEL_SIZE * 0.1;
	uv = fract(uv) * step(random(floor(uv)), 0.1);
	COLOR = texture(TEXTURE, uv);
}
