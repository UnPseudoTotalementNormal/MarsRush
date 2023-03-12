shader_type canvas_item;

void vertex() {
  // Animate Sprite2D moving in big circle around its location
  VERTEX += vec2(cos(TIME)*10.0, sin(TIME)*10.0);
}