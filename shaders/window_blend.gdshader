shader_type canvas_item;

uniform sampler2D tex_b : filter_nearest;
uniform float mix_t : hint_range(0.0, 1.0) = 0.0;
uniform bool overlay = false;

void fragment() {
	vec4 sky = texture(TEXTURE, UV);
	if (overlay) {
		COLOR = vec4(sky.rgb, sky.a * mix_t);
	} else {
		COLOR = mix(sky, texture(tex_b, UV), mix_t);
	}
}
