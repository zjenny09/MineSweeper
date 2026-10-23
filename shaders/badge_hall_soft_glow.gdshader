shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 radiance_color : source_color = vec4(1.0, 0.8, 0.28, 0.88);
uniform float intensity : hint_range(0.0, 1.5, 0.05) = 1.05;
uniform float animation_speed : hint_range(0.1, 2.0, 0.05) = 0.62;
uniform float aspect_ratio : hint_range(0.5, 3.0, 0.01) = 1.72;

float soft_glint(vec2 uv, vec2 center, float size, float phase) {
	vec2 offset = uv - center;
	offset.x *= aspect_ratio;
	float distance_to_center = length(offset);
	float pulse = 0.68 + 0.32 * (
		sin(TIME * animation_speed * 3.2 + phase) * 0.5 + 0.5
	);
	float core = 1.0 - smoothstep(0.0, size * 1.35, distance_to_center);
	float horizontal = (
		(1.0 - smoothstep(0.0, size * 0.24, abs(offset.y)))
		* (1.0 - smoothstep(size * 0.7, size * 6.8, abs(offset.x)))
	);
	float vertical = (
		(1.0 - smoothstep(0.0, size * 0.24, abs(offset.x)))
		* (1.0 - smoothstep(size * 0.7, size * 6.8, abs(offset.y)))
	);
	float diagonal_a = (
		(1.0 - smoothstep(0.0, size * 0.3, abs(offset.x - offset.y)))
		* (1.0 - smoothstep(size * 0.7, size * 4.2, distance_to_center))
	);
	float diagonal_b = (
		(1.0 - smoothstep(0.0, size * 0.3, abs(offset.x + offset.y)))
		* (1.0 - smoothstep(size * 0.7, size * 4.2, distance_to_center))
	);
	float star_shape = max(
		max(core, max(horizontal, vertical)),
		max(diagonal_a, diagonal_b) * 0.72
	);
	return star_shape * pulse;
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.x *= aspect_ratio;
	float distance_to_center = length(centered);
	float angle = atan(centered.y, centered.x);
	float time = TIME * animation_speed;
	float breathing = 0.82 + 0.18 * (sin(time * 1.15) * 0.5 + 0.5);

	float halo = (
		1.0 - smoothstep(0.1, 0.72, distance_to_center)
	) * 0.17 * breathing;

	float ray_window = (
		smoothstep(0.035, 0.13, distance_to_center)
		* (1.0 - smoothstep(0.22, 0.72, distance_to_center))
	);
	float broad_rays = pow(
		0.5 + 0.5 * cos(angle * 10.0 + time * 0.13),
		7.0
	);
	float sharp_rays = pow(
		0.5 + 0.5 * cos(angle * 10.0 + time * 0.13),
		24.0
	);
	float rays = ray_window * (
		broad_rays * 0.13 + sharp_rays * 0.25
	) * breathing;

	float sweep_coordinate = UV.x + UV.y * 0.3;
	float sweep_center = mod(time * 0.12, 1.55) - 0.12;
	float sweep = 1.0 - smoothstep(
		0.025,
		0.13,
		abs(sweep_coordinate - sweep_center)
	);
	float sweep_mask = (
		smoothstep(0.04, 0.18, UV.x)
		* (1.0 - smoothstep(0.82, 0.98, UV.x))
		* smoothstep(0.05, 0.2, UV.y)
		* (1.0 - smoothstep(0.75, 0.96, UV.y))
	);
	sweep *= sweep_mask * 0.16;

	float sparkles = 0.0;
	sparkles = max(sparkles, soft_glint(UV, vec2(0.18, 0.31), 0.024, 0.0));
	sparkles = max(sparkles, soft_glint(UV, vec2(0.36, 0.16), 0.019, 1.2));
	sparkles = max(sparkles, soft_glint(UV, vec2(0.55, 0.24), 0.026, 2.4));
	sparkles = max(sparkles, soft_glint(UV, vec2(0.77, 0.31), 0.021, 3.6));
	sparkles = max(sparkles, soft_glint(UV, vec2(0.84, 0.51), 0.018, 4.8));
	sparkles = max(sparkles, soft_glint(UV, vec2(0.64, 0.61), 0.023, 5.8));
	sparkles = max(sparkles, soft_glint(UV, vec2(0.29, 0.64), 0.019, 6.9));

	float alpha = clamp(
		(halo + rays + sweep + sparkles * 0.88) * intensity,
		0.0,
		0.78
	);
	vec3 light_color = mix(
		radiance_color.rgb,
		vec3(1.0, 0.96, 0.68),
		clamp(sparkles * 0.62 + sweep * 0.8, 0.0, 0.68)
	);
	COLOR = vec4(light_color, alpha * radiance_color.a);
}
