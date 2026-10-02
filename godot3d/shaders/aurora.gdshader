shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 aurora_a : source_color = vec4(0.10, 0.72, 0.75, 1.0);
uniform vec4 aurora_b : source_color = vec4(0.32, 0.28, 0.72, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	float ribbon = smoothstep(0.0, 0.42, sin(UV.x * 15.0 + TIME * 0.08) * 0.5 + 0.5);
	float fade = sin(UV.y * 3.14159265);
	vec3 c = mix(aurora_a.rgb, aurora_b.rgb, UV.x);
	ALBEDO = c;
	ALPHA = ribbon * fade * alpha;
}
