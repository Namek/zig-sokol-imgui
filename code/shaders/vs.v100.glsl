#version 100
attribute vec3 vertex_position;
attribute vec4 in_color;
varying vec4 color;
void main(void) {
   gl_Position = vec4(vertex_position, 1.0);
   color = in_color;
}