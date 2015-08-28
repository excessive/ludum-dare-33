uniform sampler2D u_noise;
uniform float     u_noise_strength;

const float gamma = 2.2;

vec3 filmicToneMapping(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	vec2  center = vec2(love_ScreenSize.x / 2.0, love_ScreenSize.y / 2.0);
	float aspect = love_ScreenSize.x / love_ScreenSize.y;
	float distance_from_center = distance(screen_coords, center);
	float power = 2.25;
	float offset = 2.0;
	vec4 bg  = texture2D(texture, texture_coords);
	vec4 tex = texture2D(u_noise, screen_coords / 128.0) * u_noise_strength;
	vec4 fg = (color + tex) * vec4(vec3(1.0 - pow(distance_from_center / (center.x * offset), power) + (1.0 - color.a)), 1.0);

	// if (texture_coords.x > 0.5) {
	// 	return bg * fg;
	// }
	return vec4(filmicToneMapping(pow(bg.rgb * 1.125, vec3(2.2))), 1.0) * fg;
}
