shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 snow_a : source_color = vec4(0.70, 0.82, 0.88, 1.0);
uniform vec4 snow_b : source_color = vec4(0.42, 0.60, 0.68, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	float n = hash21(floor(UV * 95.0));
	float drift = 0.5 + 0.5 * sin(UV.x * 8.0 + sin(UV.y * 13.0));
	vec3 c = mix(snow_b.rgb, snow_a.rgb, 0.68 + n * 0.18 + drift * 0.08);
	ALBEDO = c;
	ROUGHNESS = 0.91;
	METALLIC = 0.0;
	SPECULAR = 0.18;
}
