shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 1.0) = 0.1;
uniform float frequency : hint_range(0.0, 10.0) = 1.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // get the texture coordinates
    vec2 uv = SCREEN_UV;

    // calculate the displacement amount based on time and input parameters
    float time = TIME * speed;
    float displacement = amplitude * sin(uv.y * frequency + time);

    // displace the texture coordinates and sample the texture
    vec4 color = texture(SCREEN_TEXTURE, uv + vec2(0.0, displacement));

    // output the color
    COLOR = color;
}