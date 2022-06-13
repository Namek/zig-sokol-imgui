#version 330
in vec3 vertex_position;
in vec4 in_color;
out vec4 color;
void main(void) {
   gl_Position = vec4(vertex_position, 1.0);
   color = in_color;
}