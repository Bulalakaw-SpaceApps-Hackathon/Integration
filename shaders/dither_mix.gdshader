// Swap between two pixel-art textures with a 4x4 ordered dither (in 2x2 blocks), so a
// transition never makes in-between colours: every pixel is a palette colour from A or B.
// overlay = true: draw only TEXTURE where covered, transparent elsewhere (used for the dust storm).
shader_type canvas_item;

uniform sampler2D tex_b : filter_nearest;
uniform float mix_t : hint_range(0.0, 1.0) = 0.0;
uniform bool overlay = false;

const int BAYER[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	ivec2 p = ivec2(floor(UV * size / 2.0)) % 4;
	float th = (float(BAYER[p.y * 4 + p.x]) + 0.5) / 16.0;
	vec4 a = texture(TEXTURE, UV);
	bool use_b = mix_t > th;
	if (overlay) {
		COLOR = use_b ? a : vec4(0.0);
	} else {
		COLOR = use_b ? texture(tex_b, UV) : a;
	}
}
