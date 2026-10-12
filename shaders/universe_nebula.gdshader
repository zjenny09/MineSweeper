shader_type canvas_item;

uniform float flow_speed : hint_range(0.0, 2.0) = 0.055;
uniform vec3 deep_color = vec3(0.015, 0.025, 0.09);
uniform vec3 blue_color = vec3(0.10, 0.30, 0.72);
uniform vec3 violet_color = vec3(0.48, 0.14, 0.66);
uniform vec3 cyan_color = vec3(0.05, 0.50, 0.58);

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 point) {
	float value = 0.0;
	float amplitude = 0.52;
	mat2 turn = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int octave = 0; octave < 6; octave++) {
		value += noise(point) * amplitude;
		point = turn * point * 2.03 + vec2(17.2, 9.4);
		amplitude *= 0.50;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec2 space = vec2(uv.x * 1.7777778, uv.y);
	float time = TIME * flow_speed;
	float broad = fbm(space * 2.15 + vec2(time, -time * 0.18));
	float folds = fbm(space * 5.1 + vec2(-time * 0.72, time * 0.24) + broad * 1.8);
	float wisps = fbm(space * 10.0 + vec2(time * 1.3, 4.0) + folds);
	float blue_cloud = smoothstep(0.38, 0.78, broad * 0.72 + folds * 0.46);
	float violet_cloud = smoothstep(0.50, 0.88, folds * 0.68 + wisps * 0.34);
	float cyan_cloud = smoothstep(0.62, 0.93, broad * 0.42 + wisps * 0.70);
	vec3 color = deep_color;
	color += blue_color * blue_cloud * 0.72;
	color += violet_color * violet_cloud * 0.48;
	color += cyan_color * cyan_cloud * 0.30;
	float dark_lane = smoothstep(0.40, 0.68, fbm(space * 3.2 - vec2(time * 0.45, 2.7)));
	color *= mix(0.56, 1.08, dark_lane);
	float paper_fiber = sin(uv.y * 1180.0 + noise(uv * 70.0) * 8.0) * 0.5 + 0.5;
	color *= 0.965 + paper_fiber * 0.035;
	float vignette = 1.0 - smoothstep(0.24, 0.90, distance(uv, vec2(0.5)));
	color *= mix(0.70, 1.0, vignette);
	COLOR = vec4(color, 1.0);
}
