//	Starfield shader by Brian Smith (steampunkdemon.itch.io)
//	MIT licence

shader_type canvas_item;

const vec2 texture_dimensions = vec2(1024.0, 600.0); // Resolution of texture in pixels.
const vec2 star_dimensions = vec2(2.0, 2.0); // Size of a star in pixels based on texture_dimensions. Stars will only render to a maximum height of texture_dimensions.y / stars for horizontally scrolling stars or width of texture_dimensions.x / stars for vertically scrolling stars.
const float stars = 200.0; // Number of stars (rows for horizontally scrolling stars, columns for vertically scrolling stars).
const vec3 star_color = vec3(1.0, 1.0, 1.0);
const float base_scroll_speed = 20.0; // The higher the value the slower the scroll. Must be larger than 0.0 and additional_scroll_speed.
const float additional_scroll_speed = 15.0; // The higher the value the faster the scroll. Must be larger than 0.0 but smaller than base_scroll_speed.
const float preprocess = base_scroll_speed * (base_scroll_speed - additional_scroll_speed) * 3.0; // Spreads out the stars so they cover the texture from the start.
//	For horizontally scrolling stars:
const vec2 adjusted_star_dimensions = vec2(1.0 / texture_dimensions.x * star_dimensions.x, 1.0 / texture_dimensions.y * star_dimensions.y * stars);
//	For vertically scrolling stars:
//	const vec2 adjusted_star_dimensions = vec2(1.0 / texture_dimensions.x * star_dimensions.x * stars, 1.0 / texture_dimensions.y * star_dimensions.y);

float greater_than(float x, float y) {
	return max(sign(x - y), 0.0);
}

void fragment() {
//	Uncomment the following line if you are applying the shader to a TextureRect:
COLOR = texture(TEXTURE,UV);

//	Horizontally scrolling stars:
	float random_value = fract(sin(dot(floor(UV * vec2(1.0, stars)), vec2(12.9898,78.233))) * 43758.5453123);
//	If you are happy for the stars to be the full height of a row (texture_dimensions.y / stars) you can replace the following line of code with:
//	COLOR.rgb = mix(COLOR.rgb, star_color, random_value * greater_than(adjusted_star_dimensions.x, mod(UV.x + (preprocess + TIME) / (base_scroll_speed - random_value * additional_scroll_speed), 1.0)));
//	To make the stars scroll from left to right change 'mod(UV.x + (preprocess + TIME)' to 'mod(UV.x - (preprocess + TIME)'.
	COLOR.rgb = mix(COLOR.rgb, star_color, random_value * greater_than(adjusted_star_dimensions.x, mod(UV.x + (preprocess + TIME) / (base_scroll_speed - random_value * additional_scroll_speed), 1.0)) * greater_than(adjusted_star_dimensions.y, fract(UV.y * stars)));

//	Vertically scrolling stars:
//	float random_value = fract(sin(dot(floor(UV * vec2(stars, 1.0)), vec2(12.9898,78.233))) * 43758.5453123);
//	If you are happy for the stars to be the full width of a column (texture_dimensions.x / stars) you can replace the following line of code with:
//	COLOR.rgb = mix(COLOR.rgb, star_color, random_value * greater_than(adjusted_star_dimensions.y, mod(UV.y + (preprocess + TIME) / (base_scroll_speed - random_value * additional_scroll_speed), 1.0)));
//	To make the stars scroll from bottom to top change 'mod(UV.y - (preprocess + TIME)' to 'mod(UV.y + (preprocess + TIME)'.
//	COLOR.rgb = mix(COLOR.rgb, star_color, random_value * greater_than(adjusted_star_dimensions.y, mod(UV.y - (preprocess + TIME) / (base_scroll_speed - random_value * additional_scroll_speed), 1.0)) * greater_than(adjusted_star_dimensions.x, fract(UV.x * stars)));
}