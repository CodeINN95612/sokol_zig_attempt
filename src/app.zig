const global_state = @import("global_state.zig").global_state;
const Codes = @import("input.zig").Codes;
const Input = @import("input.zig");

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
const vec2 = @import("vendor/math.zig").Vec2;
const vec3 = @import("vendor/math.zig").Vec3;
const vec4 = @import("vendor/math.zig").Vec4;
const Camera = @import("camera.zig").Camera;
const QuadBatchRenderer = @import("render/quad_batch_render.zig").QuadBatchRenderer;
const SubTexture = @import("render/texture.zig").SubTexture;

const AppState = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,

    renderer: QuadBatchRenderer,

    camera: Camera,
    last_time: f64,

    subtextures: struct {
        blue_ball: SubTexture,
        red_ball: SubTexture,
    },
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

    Input.setup(&app_state.allocator) catch {
        @panic("Failed to setup Input");
    };

    global_state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.05, .g = 0.05, .b = 0.08, .a = 1 },
    };

    app_state.renderer = QuadBatchRenderer.init(&app_state.allocator, 4096) catch {
        @panic("Failed to initialize QuadBatchRenderer");
    };

    app_state.subtextures.red_ball = app_state.renderer.textures.atlas.getSubTexture(0, 0, 16, 16);
    app_state.subtextures.blue_ball = app_state.renderer.textures.atlas.getSubTexture(16, 0, 16, 16);

    stime.setup();
}

export fn frame() void {
    if (app_state.last_time == 0) {
        app_state.last_time = global_state.now();
    }

    const start_time = global_state.now();
    const dt = start_time - app_state.last_time;

    //print("dt: {d}\n", .{dt});

    //update
    {
        if (Input.was_pressed(Codes.Escape)) {
            sapp.requestQuit();
        }

        app_state.camera.update(dt);
        Input.update();
    }

    //render
    {
        sg.beginPass(.{ .action = global_state.pass_action, .swapchain = sglue.swapchain() });
        app_state.renderer.begin(app_state.camera.vp());

        //draw a grid of gray quads
        const offset = 0;
        for (0..11) |i| {
            for (0..11) |j| {
                const s = 50.0;
                const x = (@as(f32, @floatFromInt(i)) - 5) * s + offset;
                const y = (@as(f32, @floatFromInt(j)) - 5) * s + offset;

                const color = vec4.new(1, 1, 1, 1.0);
                const tex_id: f32 = app_state.renderer.textures.atlas_id;

                app_state.renderer.draw_quad(.{
                    .position = vec2.new(x, y),
                    .size = vec2.new(s, s),
                    .tint = color,
                    .uv_min = app_state.subtextures.red_ball.uv_min,
                    .uv_max = app_state.subtextures.red_ball.uv_max,
                    .tex_id = tex_id,
                });
            }
        }

        // app_state.renderer.draw_quad(.{
        //     .position = vec2.new(0, 0),
        //     .size = vec2.new(50, 50),
        //     .uv_min = app_state.subtextures.blue_ball.uv_min,
        //     .uv_max = app_state.subtextures.blue_ball.uv_max,
        //     .tex_id = app_state.renderer.textures.atlas_id,
        // });

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

    Input.on_event(e);

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
    Input.shutdown();

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
