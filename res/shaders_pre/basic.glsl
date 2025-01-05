@vs vs
in vec4 position;
in vec4 color0;

layout(binding=0) uniform vs_params {
    mat4 mvp;
};

out vec4 color;

void main() {
    gl_Position = mvp * position;
    color = color0;
}

@end

@fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}

@end

@program basic vs fs