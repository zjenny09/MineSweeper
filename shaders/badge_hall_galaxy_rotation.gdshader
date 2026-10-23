shader_type canvas_item;

uniform float rotation_angle = 0.0;
uniform float aspect_ratio = 2.0;
uniform vec2 pivot_uv = vec2(0.5, 0.5);

void fragment() {
	vec2 point = UV - pivot_uv;
	point.x *= aspect_ratio;
	float cosine = cos(rotation_angle);
	float sine = sin(rotation_angle);
	vec2 rotated = vec2(
		point.x * cosine - point.y * sine,
		point.x * sine + point.y * cosine
	);
	rotated.x /= aspect_ratio;
	vec2 sample_uv = rotated + pivot_uv;
	if (
		sample_uv.x < 0.0
		|| sample_uv.x > 1.0
		|| sample_uv.y < 0.0
		|| sample_uv.y > 1.0
	) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, sample_uv) * COLOR;
	}
}
