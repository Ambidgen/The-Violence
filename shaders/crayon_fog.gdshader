shader_type canvas_item;
// The fog of war in charcoal (1.4): the veil's cells carry how unknown the ground is; the
// shader lays it on as hatching in world space, one direction where the ground has been
// seen, crossing strokes where it never has, shivering with the page's boil frame.
uniform float boil = 0.0;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float strokes(vec2 w, float ang, float spacing, float seed) {
	vec2 d = vec2(cos(ang), sin(ang));
	float u = dot(w, vec2(-d.y, d.x)) / spacing;
	float row = floor(u);
	float along = dot(w, d) / 40.0;
	float wob = (hash(vec2(row, floor(along) + seed + boil * 7.0)) - 0.5) * 0.35;
	float f = abs(fract(u + wob) - 0.5);
	float press = 0.55 + 0.45 * hash(vec2(row, seed + boil));
	return smoothstep(0.34, 0.12, f) * press;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	float s1 = strokes(world, -0.7, 4.0, 1.0);
	float s2 = strokes(world, 0.9, 4.6, 5.0);
	float unseen = smoothstep(0.45, 0.6, a);
	float cover = mix(0.5 + 0.5 * s1, 0.62 + 0.38 * max(s1, s2), unseen);
	COLOR = vec4(0.07, 0.07, 0.08, clamp(a * cover * 1.3, 0.0, 0.96));
}
