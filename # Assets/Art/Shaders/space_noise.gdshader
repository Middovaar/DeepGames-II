shader_type canvas_item;

render_mode world_vertex_coords;
uniform sampler2D noise_texture : filter_nearest, repeat_enable; 
uniform float scale = 0.01;
uniform float min_scale = 0.01;

void fragment() {
    vec2 world_pos = VERTEX;
	
    vec4 noise = texture(noise_texture, world_pos * scale * min_scale);

    COLOR = noise; 
}
