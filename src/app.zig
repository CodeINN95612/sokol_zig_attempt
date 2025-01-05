const global_state = @import("global_state.zig").global_state;
const Codes = @import("input.zig").Codes;
const Input = @import("input.zig").Input;

const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const print = @import("std").debug.print;
const shd = @import("shaders/basic.glsl.zig");

const std = @import("std");
const mat4 = @import("vendor/math.zig").Mat4;
const vec3 = @import("vendor/math.zig").Vec3;
const Camera = @import("camera.zig").Camera;

const AppState = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,

    camera: Camera,
};

var app_state: AppState = undefined;

export fn init() void {
    app_state.gpa = std.heap.GeneralPurposeAllocator(.{}){};
    app_state.allocator = app_state.gpa.allocator();

    const width = @as(f32, @floatFromInt(sapp.width()));
    const height = @as(f32, @floatFromInt(sapp.height()));
    app_state.camera = Camera.init(width, height, vec3.new(0, 0, -1));

    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    print("Backend: {}\n", .{sg.queryBackend()});

    global_state.input = Input.init(app_state.allocator);

    global_state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.05, .g = 0.05, .b = 0.08, .a = 1 },
    };

    global_state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .type = .VERTEXBUFFER,
        .data = sg.asRange(&[_]f32{
            // positions      colors
            -0.5, 0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
            0.5,  0.5,  0.5, 0.0, 1.0, 0.0, 1.0,
            0.5,  -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
            -0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0,
        }),
    });

    global_state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(&[_]u16{
            0, 1, 2,
            0, 2, 3,
        }),
    });

    global_state.pipe = sg.makePipeline(.{
        .shader = sg.makeShader(shd.basicShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.attrs[shd.ATTR_basic_position].format = .FLOAT3;
            l.attrs[shd.ATTR_basic_color0].format = .FLOAT4;
            break :init l;
        },
    });
}

export fn frame() void {
    //update
    {
        const ginput = &global_state.input;
        if (ginput.was_pressed(Codes.Escape)) {
            sapp.requestQuit();
        }

        app_state.camera.update(0);
        ginput.update();
    }

    //render
    {
        sg.beginPass(.{ .action = global_state.pass_action, .swapchain = sglue.swapchain() });

        sg.applyPipeline(global_state.pipe);
        sg.applyBindings(global_state.bind);

        const proj = mat4.ortho(-10, 10, -10, 10, -1, 1);
        const view = mat4.translate(vec3.new(0, 0, -1));

        const tmp = mat4.mul(proj, view);
        _ = tmp;

        const vs_params = .{
            .mvp = app_state.camera.vp(),
        };

        sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));

        sg.draw(0, 6, 1);

        sg.endPass();
        sg.commit();
    }
}

export fn input(ev: ?*const sapp.Event) void {
    if (ev == null) {
        return;
    }
    const e = ev.?;

    global_state.input.on_event(e);

    switch (e.type) {
        .RESIZED => {
            const width = @as(f32, @floatFromInt(e.window_width));
            const height = @as(f32, @floatFromInt(e.window_height));
            app_state.camera.on_resize(width, height);
        },
        .MOUSE_SCROLL => {
            app_state.camera.on_scroll(e.scroll_y);
        },
        else => {},
    }
}

export fn cleanup() void {
    sg.shutdown();

    global_state.input.deinit();

    const deinit_status = app_state.gpa.deinit();
    if (deinit_status == .leak) @panic("TEST FAIL");
}

pub const App = struct {
    pub fn run() void {
        sapp.run(.{
            .init_cb = init,
            .frame_cb = frame,
            .cleanup_cb = cleanup,
            .event_cb = input,
            .width = 640,
            .height = 480,
            .icon = .{ .sokol_default = true },
            .window_title = "clear.zig",
            .logger = .{ .func = slog.func },
            .win32_console_attach = true,
        });
    }
};
