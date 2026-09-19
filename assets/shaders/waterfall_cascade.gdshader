shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 water_color : source_color = vec4(0.18, 0.75, 0.98, 0.82);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 0.95);
uniform float flow_speed : hint_range(0.5, 6.0) = 2.4;

void fragment() {
	float flow = fract(UV.y * 2.5 - TIME * flow_speed);
	float foam = smoothstep(0.72, 0.92, sin(flow * 6.28318 + sin(UV.x * 10.0) * 1.5));
	vec4 col = mix(water_color, foam_color, foam * 0.65);
	ALBEDO = col.rgb;
	ALPHA = col.a;
	ROUGHNESS = 0.08;
	SPECULAR = 0.85;
	EMISSION = col.rgb * 0.22;
}
