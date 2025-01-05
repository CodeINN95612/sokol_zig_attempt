const Vertex = @import("vertex.zig").Vertex;
const sg = @import("sokol").gfx;
const std = @import("std");
const shd = @import("../shaders/basic.glsl.zig");
const vec3 = @import("../vendor/math.zig").Vec3;
const vec4 = @import("../vendor/math.zig").Vec4;
const mat4 = @import("../vendor/math.zig").Mat4;

pub const QuadDescription = struct {
    position: vec3,
    rotation: f32 = 0.0,
    scale: vec3 = vec3.new(1.0, 1.0, 1.0),
    color: vec4 = vec4.new(1.0, 1.0, 1.0, 1.0),
};

pub const QuadBatchRenderer = struct {
    max_quads: usize,
    max_vertices: usize,
    max_indexes: usize,

    allocator: *std.mem.Allocator,
    current_quad_count: usize,
    quad_vertex_positions: [4]vec4,
    vertex_data: []Vertex,
    index_data: []u16,
    vertex_buffer: sg.Buffer,
    index_buffer: sg.Buffer,
    shader: sg.Shader,
    pipeline: sg.Pipeline,
    vp: mat4,

    pub fn init(allocator: *std.mem.Allocator, max_quads: usize) QuadBatchRenderer {
        const max_vertices = max_quads * 4;
        const max_indexes = max_quads * 6;

        const shader = sg.makeShader(shd.basicShaderDesc(sg.queryBackend()));
        const pipe = sg.makePipeline(.{
            .shader = shader,
            .index_type = .UINT16,
            .layout = init: {
                var l = sg.VertexLayoutState{};
                l.attrs[shd.ATTR_basic_position].format = .FLOAT4;
                l.attrs[shd.ATTR_basic_color0].format = .FLOAT4;
                break :init l;
            },
        });

        var renderer = QuadBatchRenderer{
            .max_quads = max_quads,
            .max_vertices = max_vertices,
            .max_indexes = max_indexes,
            .allocator = allocator,
            .current_quad_count = 0,
            .vertex_data = allocator.alloc(Vertex, max_vertices) catch unreachable,
            .index_data = allocator.alloc(u16, max_indexes) catch unreachable,
            .vertex_buffer = sg.makeBuffer(.{ .type = .VERTEXBUFFER, .size = @sizeOf(Vertex) * max_vertices, .usage = .STREAM }),
            .index_buffer = sg.makeBuffer(.{ .type = .INDEXBUFFER, .size = @sizeOf(u16) * max_indexes, .usage = .DYNAMIC }),
            .shader = shader,
            .pipeline = pipe,
            .quad_vertex_positions = .{
                vec4.new(-0.5, 0.5, 0.0, 1.0),
                vec4.new(0.5, 0.5, 0.0, 1.0),
                vec4.new(0.5, -0.5, 0.0, 1.0),
                vec4.new(-0.5, -0.5, 0.0, 1.0),
            },
            .vp = mat4.identity(),
        };

        // Fill index buffer with static data
        var indices: []u16 = renderer.index_data[0..renderer.max_indexes];
        var index_offset: u16 = 0;
        for (0..renderer.max_quads) |quad_idx| {
            indices[quad_idx * 6 + 0] = index_offset + 0;
            indices[quad_idx * 6 + 1] = index_offset + 1;
            indices[quad_idx * 6 + 2] = index_offset + 2;
            indices[quad_idx * 6 + 3] = index_offset + 2;
            indices[quad_idx * 6 + 4] = index_offset + 3;
            indices[quad_idx * 6 + 5] = index_offset + 0;
            index_offset += 4;
        }
        sg.updateBuffer(renderer.index_buffer, sg.asRange(indices[0..]));

        return renderer;
    }

    pub fn deinit(self: *QuadBatchRenderer) void {
        self.allocator.free(self.vertex_data);
        self.allocator.free(self.index_data);
    }

    pub fn begin(self: *QuadBatchRenderer, vp: mat4) void {
        self.vp = vp;
    }

    pub fn draw_quad(self: *QuadBatchRenderer, qd: QuadDescription) void {
        if (self.current_quad_count >= self.max_quads) {
            self.flush();
        }

        var transform = mat4.identity();
        transform = transform.translate(qd.position);
        transform = transform.rotate(qd.rotation, vec3.new(0.0, 0.0, 1.0));
        transform = transform.scale(qd.scale);

        const base_vertex = self.current_quad_count * 4;
        self.vertex_data[base_vertex + 0] = .{ .position = transform.mulByVec4(self.quad_vertex_positions[0]), .color = qd.color };
        self.vertex_data[base_vertex + 1] = .{ .position = transform.mulByVec4(self.quad_vertex_positions[1]), .color = qd.color };
        self.vertex_data[base_vertex + 2] = .{ .position = transform.mulByVec4(self.quad_vertex_positions[2]), .color = qd.color };
        self.vertex_data[base_vertex + 3] = .{ .position = transform.mulByVec4(self.quad_vertex_positions[3]), .color = qd.color };

        self.current_quad_count += 1;
    }

    pub fn flush(self: *QuadBatchRenderer) void {
        if (self.current_quad_count == 0) {
            return;
        }

        sg.updateBuffer(self.vertex_buffer, sg.asRange(self.vertex_data[0 .. self.current_quad_count * 4]));

        var bindings = sg.Bindings{};
        bindings.vertex_buffers[0] = self.vertex_buffer;
        bindings.index_buffer = self.index_buffer;

        sg.applyPipeline(self.pipeline);
        sg.applyBindings(bindings);

        const vs_params = .{
            .mvp = self.vp,
        };
        sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));

        sg.draw(0, @intCast(self.current_quad_count * 6), 1);

        self.current_quad_count = 0;
    }

    pub fn end(self: *QuadBatchRenderer) void {
        self.flush();
    }
};
