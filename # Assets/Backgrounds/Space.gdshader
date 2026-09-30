shader_type canvas_item;

uniform float starDensity : hint_range(0.0, 1.0) = 0.6;
uniform vec2 SpaceSpeed = vec2(0.0, 0.0);
uniform vec2 SpaceSpeedScalar = vec2(0.0, 0.0);
uniform vec2 global_offset = vec2(10, 0.0);
uniform float base_size = 1.0;
uniform float trail_scale = 0.1; // How long the smears get at max speed

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

// Generates a single parallax layer with randomized star offsets
float get_stars(vec2 uv, float grid_size, float density, vec2 offset, vec2 velocity, float size, vec2 layer_seed) {
    vec2 pos = uv + offset;
    vec2 grid_id = floor(pos / grid_size);
    vec2 local_pos = fract(pos / grid_size) * grid_size;

    float color = 0.0;

    // Check the 3x3 neighborhood so trails and offsets don't clip at cell boundaries
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
                vec2 ba = velocity;
                
                // Find the closest point on the trail's line segment
                float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
                vec2 diff = pa - ba * h;

                // AABB check to keep stars rendering as sharp square pixels along the trail
                if (max(abs(diff.x), abs(diff.y)) < size * 0.025) {
                    color = 1.0;
                }
            }
        }
    }
    return color;
}

void fragment() {
    // Convert UVs to pixel coord
    vec2 pixel_pos = UV * (1.0 / TEXTURE_PIXEL_SIZE);
    float final_stars = 0.0;

    // Layer 1 (Far Background)
    float size1 = max(1.0, base_size * 0.2);
    vec2 offset1 = global_offset * 0.2;
    vec2 vel1 = SpaceSpeed * trail_scale * 0.2 * 0.2;
    final_stars += get_stars(pixel_pos, 2.0, starDensity, offset1, vel1, size1, vec2(0.0, 0.0));

    // Layer 2 (Midground)
    float size2 = max(1.5, base_size * 0.6);
    vec2 offset2 = global_offset * 0.5;
    vec2 vel2 = SpaceSpeed * trail_scale * 0.5 * 0.2;
    final_stars += get_stars(pixel_pos, 6.0, starDensity * 0.8, offset2, vel2, size2, vec2(100.0, 200.0));

    // Layer 3 (Foreground)
    float size3 = base_size;
    vec2 offset3 = global_offset * 1.0;
    vec2 vel3 = SpaceSpeed * trail_scale * 1.0 * 0.2;
    final_stars += get_stars(pixel_pos, 30.0, starDensity * 0.5, offset3, vel3, size3, vec2(300.0, 400.0));

    // Output white pixels where stars exist, transparent elsewhere
    COLOR = vec4(1.0, 1.0, 1.0, clamp(final_stars, 0.0, 1.0));
}