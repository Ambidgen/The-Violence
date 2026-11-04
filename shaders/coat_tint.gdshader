shader_type canvas_item;
// 1.4: a civilian's own coat colour on the shared pale coat of the crayon figure: only
// the pale, unsaturated wax takes the tint, so skin, hair, boots and outlines keep theirs.
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.333));
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	float m = smoothstep(0.45, 0.62, l) * (1.0 - smoothstep(0.1, 0.22, sat));
	c.rgb = mix(c.rgb, c.rgb * tint.rgb * 1.12, m);
	COLOR = c * COLOR;
}
