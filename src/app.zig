const global_state = @import("global_state.zig").global_state;
const Codes = @import("input.zig").Codes;
const Input = @import("input.zig").Input;

const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const stime = sokol.time;
const print = @import("std").debug.print;
const shd = @import("shaders/basic.glsl.zig");

const std = @import("std");
const mat4 = @import("vendor/math.zig").Mat4;
const vec3 = @import("vendor/math.zig").Vec3;
const vec4 = @import("vendor/math.zig").Vec4;
const Camera = @import("camera.zig").Camera;
const QuadBatchRenderer = @import("render/quad_batch_render.zig").QuadBatchRenderer;

const AppState = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,

    renderer: QuadBatchRenderer,

    camera: Camera,
    last_time: f64,
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

    app_state.renderer = QuadBatchRenderer.init(&app_state.allocator, 4096);

    stime.setup();
}

export fn frame() void {
    if (app_state.last_time == 0) {
        app_state.last_time = global_state.now();
    }

    const start_time = global_state.now();
    const dt = start_time - app_state.last_time;

    print("dt: {d}\n", .{dt});

    //update
    {
        const ginput = &global_state.input;
        if (ginput.was_pressed(Codes.Escape)) {
            sapp.requestQuit();
        }

        app_state.camera.update(dt);
        ginput.update();
    }

    //render
    {
        sg.beginPass(.{ .action = global_state.pass_action, .swapchain = sglue.swapchain() });
        app_state.renderer.begin(app_state.camera.vp());

        //draw a grid of gray quads
        const offset = 2.0;
        for (0..10) |i| {
            for (0..10) |j| {
                const x = @as(f32, @floatFromInt(i)) * offset;
                const y = @as(f32, @floatFromInt(j)) * offset;
                app_state.renderer.draw_quad(.{
                    .position = vec3.new(x, y, 0),
                    .color = vec4.new(0.5, 0.5, 0.5, 1),
                });
            }
        }

        app_state.renderer.end();

        sg.endPass();
        sg.commit();
    }

    app_state.last_time = start_time;
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

    app_state.renderer.deinit();
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
