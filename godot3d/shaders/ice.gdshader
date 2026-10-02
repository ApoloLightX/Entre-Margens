shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 ice_deep : source_color = vec4(0.035, 0.28, 0.42, 1.0);
uniform vec4 ice_light : source_color = vec4(0.48, 0.90, 1.0, 1.0);
uniform vec4 ice_core : source_color = vec4(0.74, 0.97, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.42;

void fragment() {
	float bands = 0.5 + 0.5 * sin(UV.x * 41.0 + sin(UV.y * 27.0) * 2.0);
	float cracks = smoothstep(0.78, 0.98, abs(sin(UV.x * 73.0 + UV.y * 39.0)));
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	vec3 base = mix(ice_deep.rgb, ice_light.rgb, 0.22 + bands * 0.18);
	base = mix(base, ice_core.rgb, fresnel * 0.58 + cracks * 0.12);
	ALBEDO = base;
	ROUGHNESS = 0.18 + (1.0 - bands) * 0.15;
	METALLIC = 0.06;
	SPECULAR = 0.72;
	EMISSION = ice_core.rgb * (fresnel * 0.22 + cracks * 0.08) * glow_strength;
}
