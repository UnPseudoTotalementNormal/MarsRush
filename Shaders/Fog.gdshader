shader_type canvas_item;

uniform float density : hint_range(0.0, 1.0) = 0.2;
uniform vec4 fog_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fog_opacity : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Fonction de bruit de Perlin personnalisée
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec2 rg = textureLod(SCREEN_TEXTURE, uv * 0.01, 0.0).yx;
    return mix(rg.x, rg.y, f.z);
}

void fragment() {
    float distance = length(SCREEN_UV);
    float threshold = pow(density, 2.0) * 200.0;
    float n = abs(noise(vec3(SCREEN_UV * 30.0, 1)));
    float fog_density = (distance * threshold) + (n * 100.0);
    fog_density = clamp(fog_density, 0.0, 1.0);
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
    color = mix(color, fog_color, fog_density * fog_opacity);
    COLOR = color;
}
