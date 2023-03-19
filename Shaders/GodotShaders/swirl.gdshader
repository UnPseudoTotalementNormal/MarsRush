shader_type canvas_item;
 
uniform float ratio : hint_range(0.0, 1.0) = 0.1;
 
uniform float power = 3.0;
 
uniform float min_speed = 10.0;
 
uniform float max_speed = 90.0;
 
void fragment() {
    vec2 uv = UV;
    
    uv *= 2.0;
    uv -= vec2(1.0);
    
    float len = length(uv);
 
    float rspeed = mix(max_speed, min_speed, len);
    
    float sinx = sin((1. - ratio) * rspeed);
    float cosx = cos((1. - ratio) * rspeed);
 
    vec2 trs = uv * mat2(vec2(cosx, sinx), vec2(-sinx, cosx));
    trs /= pow(ratio, power);
    
    trs += vec2(1.0);
    trs /= 2.;
    if(trs.x > 1. || trs.x < 0. || trs.y > 1. || trs.y < 0.) {
        // Prevent sprite leaking.
        COLOR = vec4(0.);
    } else {
        vec4 col = texture(TEXTURE, trs);   
    	COLOR = col;
    }
}