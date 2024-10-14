shader_type spatial;
uniform vec3 albedo: source_color = vec3(1.0);

uniform sampler2D normalmap_tex: repeat_enable, filter_linear;
uniform sampler2D normalmap_tex2: repeat_enable, filter_linear;

uniform vec2 direction1 = vec2(1.0,0.0);
uniform vec2 direction2 = vec2(1.0,0.0);
uniform float scroll_speed1: hint_range(0.0, 1.0) = 0.1;
uniform float scroll_speed2: hint_range(0.0, 1.0) = 0.1;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 offset1 = scroll_speed1 * direction1 * TIME;
	vec2 offset2 = scroll_speed2 * direction2 * TIME;
	vec3 normal = texture(normalmap_tex, UV + offset1).rgb;
	vec3 normal2 = texture(normalmap_tex2, UV + offset2).rgb;
	vec3 super_normal = normal *0.5 + normal2*0.5;

	NORMAL_MAP = super_normal;
	ALBEDO = albedo;
	ROUGHNESS = 0.0;
	METALLIC = 0.01;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
