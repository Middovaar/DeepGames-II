shader_type canvas_item;

// Assign your NoiseTexture2D here in the Inspector
uniform sampler2D noise_texture : filter_nearest, repeat_enable; 
uniform float scale = 0.01;
uniform float min_scale = 0.01;

void fragment() {
    vec2 world_pos = (SCREEN_UV / SCREEN_PIXEL_SIZE);
    world_pos = (vec4(world_pos, 0.0, 1.0)).xy;
	
    vec4 noise = texture(noise_texture, world_pos * scale * min_scale);

    COLOR = noise; 
}
