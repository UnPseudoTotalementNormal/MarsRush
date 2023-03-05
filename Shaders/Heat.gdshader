shader_type canvas_item;

uniform float speed = 2.0;
uniform float strength = 0.1;

void fragment() {
    vec2 uv = UV;
    vec4 tex = texture(TEXTURE, uv);
    
    // Offset x et y selon la position de l'onde de chaleur
    uv.y += (sin(TIME * speed + uv.x * 10.0) * strength);
    uv.x += (sin(TIME * speed + uv.y * 10.0) * strength);
    
    // Obtenir la couleur de la texture décalée
    vec4 heat = texture(TEXTURE, uv);
    
    // Interpolation entre la couleur de la texture d'origine et la couleur de la texture décalée
    vec4 col = mix(tex, heat, strength * 2.0);
    
    // Assigner la couleur à la sortie
    COLOR = col;
}