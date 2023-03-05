shader_type canvas_item;

uniform vec2 distortion = vec2(0.2, 0.2);
uniform float speed = 1.0;
uniform float amplitude = 0.05;
uniform sampler2D texture;

void fragment() {
    // Récupérer la position du pixel et les coordonnées de texture
    vec2 uv = UV;
    vec2 texcoord = uv;

    // Déplacer les coordonnées de texture en fonction du temps et de la vitesse
    texcoord += vec2(0.0, -TIME * speed);

    // Ajouter une distorsion à la position en utilisant une fonction sinusoïdale
    float distortionX = sin(texcoord.y * 10.0) * distortion.x * amplitude;
    float distortionY = sin(texcoord.x * 10.0) * distortion.y * amplitude;
    vec2 distortion2 = vec2(distortionX, distortionY);
    texcoord += distortion2;

    // Appliquer la texture modifiée
    vec4 texcolor = texture(TEXTURE, texcoord);

    // Sortie de la couleur modifiée
    COLOR = texcolor;
}
