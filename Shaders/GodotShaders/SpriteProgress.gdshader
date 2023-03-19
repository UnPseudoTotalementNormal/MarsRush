// UPDATED VERSION FOR GODOT 4

shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform float strength : hint_range(0.0,1.0) = 0.0;

void fragment() {
	vec4 custom_color = texture(TEXTURE, UV);
	
	if (1.0 - UV.y <= progress && custom_color.a != 0.0) {
		custom_color.rgb = mix(custom_color.rgb, overlay_color.rgb, strength);
		custom_color.a = COLOR.a;
		
		COLOR = custom_color;
	}
}