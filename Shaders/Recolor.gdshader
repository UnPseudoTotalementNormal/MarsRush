shader_type canvas_item;
uniform vec4 newcolor: source_color;

void fragment() {
    // Accède à la texture de la TileMap2D
    vec4 texture_color = texture(TEXTURE, UV);

    // Modifie la couleur de la texture en la multipliant par du rouge
    vec4 modulated_color = texture_color * newcolor;

    // Utilise la valeur d'alpha de la texture originale pour mélanger les couleurs
    COLOR = mix(texture_color, modulated_color, modulated_color.a);
}