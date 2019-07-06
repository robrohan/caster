precision mediump float;
precision mediump int;

//////////////////////////////////////////////////////

attribute vec3 position;

varying vec2 v_texcoord;

const vec2 MADD = vec2(0.5, 0.5);
void main() {
  v_texcoord = position.xy * MADD + MADD;
  gl_Position = vec4(position, 1.0);
}
