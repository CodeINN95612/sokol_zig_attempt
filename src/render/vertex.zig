const vec2 = @import("../vendor/math.zig").Vec2;
const vec3 = @import("../vendor/math.zig").Vec3;
const vec4 = @import("../vendor/math.zig").Vec4;

pub const Vertex = struct {
    position: vec4,
    color: vec4,
    tex_data: vec4,
};
