shader_type canvas_item;

uniform float starDensity : hint_range(0.0, 3.0) = 0.6;
uniform float starFrequency : hint_range(0.0, 4.0) = 1.0;
uniform vec2 SpaceSpeed = vec2(0.0, 0.0);
uniform vec2 SpaceSpeedScalar = vec2(0.0, 0.0);
uniform vec2 global_offset = vec2(10.0, 0.0);
uniform float base_size = 1.0;
uniform float trail_scale = 0.3; // How long the smears get at max speed
uniform vec2 texture_size = vec2(16.0, 16.0); // Base size of the assigned texture in pixels

// Pseudo-random float generator [0.0, 1.0]
float rand(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
}

// Pseudo-random 2D vector generator [0.0, 1.0] for intra-cell star offsets
vec2 rand2(vec2 st) {
    return vec2(
        rand(st + vec2(1.0, 0.0)),
        rand(st + vec2(0.0, 1.0))
    );
}

// Generates a single parallax layer with a crisp texture at the front and a trail behind
vec4 get_stars(sampler2D tex, vec2 uv, float grid_size, float density, vec2 offset, vec2 velocity, float size, vec2 layer_seed) {
    vec2 pos = uv + offset;
    vec2 grid_id = floor(pos / grid_size);
    vec2 local_pos = fract(pos / grid_size) * grid_size;

    vec4 final_layer_color = vec4(0.0);

    // Check the 3x3 neighborhood so textures and trails don't clip at cell boundaries
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 neighbor_offset = vec2(x, y);
            vec2 neighbor_id = grid_id + neighbor_offset + layer_seed;

            if (rand(neighbor_id) < density) {
                // Randomize position inside cell (bounded between 10% and 90% to prevent clipping)
                vec2 rand_pos = rand2(neighbor_id);
                vec2 star_offset_in_cell = (vec2(0.1) + 0.8 * rand_pos) * grid_size;
                
                // Position of the star relative to local_pos origin
                vec2 star_pos = neighbor_offset * grid_size + star_offset_in_cell;
                
                // Vector from star center to current pixel
                vec2 pa = local_pos - star_pos;
                
                // Effective dimensions of the texture scaled by layer size
                vec2 effective_size = (texture_size * size) * vec2(0.008, 0.01) * 3.0;
                vec2 half_size = effective_size * 0.5;

                vec4 star_color = vec4(0.0);

                // 1. Render the crisp, un-smeared texture at the star's head position
                if (abs(pa.x) <= half_size.x && abs(pa.y) <= half_size.y) {
                    vec2 tex_uv = (pa / effective_size) + 0.5;
                    star_color = texture(tex, tex_uv);
                }
                // 2. Render the trail behind the star (opposite to velocity direction)
                else if (dot(velocity, velocity) > 0.0001) {
                    vec2 ba_trail = -velocity; // Points backward from the star
                    float h = clamp(dot(pa, ba_trail) / dot(ba_trail, ba_trail), 0.0, 1.0);
                    vec2 diff = pa - ba_trail * h;
                    
                    // Thin trail width scaled with star size
                    float trail_thickness = max(0.5, size * 0.5);
                    if (abs(diff.x) < trail_thickness && abs(diff.y) < trail_thickness) {
                        float fade = 1.0 - h; // Fades out towards the tail
                        star_color = vec4(1.0, 1.0, 1.0, fade * 0.6); // White glowing trail
                    }
                }

                // Alpha blend overlapping stars/trails
                if (star_color.a > 0.0) {
                    final_layer_color = mix(final_layer_color, star_color, star_color.a);
                }
            }
        }
    }
    return final_layer_color;
}

void fragment() {
    // Convert UVs to pixel coordinates
    vec2 pixel_pos = UV * (10.0 / TEXTURE_PIXEL_SIZE);
    vec4 final_color = vec4(0.0);

    // Layer 1 (Far Background)
    float size1 = max(0.5, base_size * 0.2);
    vec2 offset1 = global_offset * 0.2;
    vec2 vel1 = SpaceSpeed * trail_scale * 0.2 * 0.2;
    vec4 col1 = get_stars(TEXTURE, pixel_pos, 2.0, starDensity, offset1, vel1, size1, vec2(0.0, 0.0));
    final_color = mix(final_color, col1, col1.a);

    // Layer 2 (Midground)
    float size2 = max(0.8, base_size * 0.5);
    vec2 offset2 = global_offset * 0.5;
    vec2 vel2 = SpaceSpeed * trail_scale * 0.5 * 0.2;
    vec4 col2 = get_stars(TEXTURE, pixel_pos, 6.0, starDensity * 0.8, offset2, vel2, size2, vec2(100.0, 200.0));
    final_color = mix(final_color, col2, col2.a);

    // Layer 3 (Foreground)
    float size3 = base_size;
    vec2 offset3 = global_offset * 1.0;
    vec2 vel3 = SpaceSpeed * trail_scale * 1.0 * 0.2;
    vec4 col3 = get_stars(TEXTURE, pixel_pos, 30.0, starDensity * 0.5, offset3, vel3, size3, vec2(300.0, 400.0));
    final_color = mix(final_color, col3, col3.a);

    // Output the combined color
    COLOR = final_color;
}