shader_type canvas_item;

// New character parts use this warm reference for skin. Recolour only nearby
// pixels, preserving pencil grain and the clothing/helmet colours. The rig picks
// the same tone for its animated hands.
uniform vec4 skin_tone : source_color = vec4(0.84, 0.64, 0.50, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 reference = vec3(0.839, 0.635, 0.498);
	float mask = 1.0 - smoothstep(0.09, 0.21, distance(tex.rgb, reference));
	float shade = clamp(tex.r / reference.r, 0.0, 1.2);
	tex.rgb = mix(tex.rgb, skin_tone.rgb * shade, mask);
	COLOR *= tex;
}
