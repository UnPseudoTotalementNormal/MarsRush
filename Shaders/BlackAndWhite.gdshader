shader_type canvas_item;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform bool activated;

void fragment() {
	if (activated) {
		float luminance = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		luminance *= intensity;
	    COLOR = vec4(luminance, luminance, luminance, COLOR.a);
	}
}