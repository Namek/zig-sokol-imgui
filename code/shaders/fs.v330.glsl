#version 330
out vec4 frag_color;
in vec4 color;
void main(void) {
    frag_color = color;
}