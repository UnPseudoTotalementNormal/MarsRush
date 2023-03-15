shader_type canvas_item;

uniform float threshold : hint_range(0, 1) = 0.5;

void vertex() {
    // Convertir la position horizontale du vertex en pixels.
    UV.y = (UV.y + TEXTURE_PIXEL_SIZE.y / 2.0) / TEXTURE_PIXEL_SIZE.y;
}

void fragment() {
    if (UV.y > 2.0 * threshold * TEXTURE_PIXEL_SIZE.y) {
        true;
    }
	else {
		discard;
	}
}