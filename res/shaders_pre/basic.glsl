@vs vs
in vec4 position;
in vec4 color0;
in vec4 v_tex_data;

layout(binding=0) uniform vs_params {
    mat4 mvp;
};

out vec4 color;
out vec2 f_uv;
out flat float f_tex_id;

void main() {
    gl_Position = mvp * position;
    color = color0;
    f_uv = v_tex_data.xy;
    f_tex_id = v_tex_data.z;
}

@end

@fs fs
layout (binding=0) uniform texture2D tex0;
layout (binding=1) uniform texture2D tex1;
layout (binding=0) uniform sampler smp;

in vec4 color;
in vec2 f_uv;
in flat float f_tex_id;

out vec4 frag_color;

void main() {

    int tex_id = int(f_tex_id);

    vec4 tex_color = texture(sampler2D(tex0, smp), f_uv);
    switch (tex_id){
        case 1: tex_color = texture(sampler2D(tex1, smp), f_uv); break;
    }

    frag_color = tex_color * color;
}

@end

@program basic vs fs