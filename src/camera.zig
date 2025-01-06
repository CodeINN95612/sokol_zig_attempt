const vec3 = @import("vendor/math.zig").Vec3;
const mat4 = @import("vendor/math.zig").Mat4;
const gs = @import("global_state.zig").global_state;
const Codes = @import("input.zig").Codes;

const sapp = @import("sokol").app;

const print = @import("std").debug.print;

pub const Camera = struct {
    width: f32,
    height: f32,
    zoom: f32 = 1.0,
    position: vec3,
    view_matrix: mat4,
    projection_matrix: mat4,
    vp_matrix: mat4,

    pub fn init(width: f32, height: f32, position: vec3) Camera {
        var camera = Camera{
            .width = width,
            .height = height,
            .position = position,
            .view_matrix = mat4.identity(),
            .projection_matrix = mat4.identity(),
            .vp_matrix = mat4.identity(),
        };
        camera.update_view();
        camera.update_projection();
        camera.update_vp();
        return camera;
    }

    pub fn vp(self: *const Camera) mat4 {
        return self.vp_matrix;
    }

    pub fn update(self: *Camera, dt: f64) void {
        const speed = 20.0 * dt;

        var direction = vec3.zero();

        if (gs.input.is_down(Codes.W)) {
            direction = direction.add(vec3.new(0, 1, 0));
        }

        if (gs.input.is_down(Codes.S)) {
            direction = direction.add(vec3.new(0, -1, 0));
        }

        if (gs.input.is_down(Codes.A)) {
            direction = direction.add(vec3.new(1, 0, 0));
        }

        if (gs.input.is_down(Codes.D)) {
            direction = direction.add(vec3.new(-1, 0, 0));
        }

        if (!direction.eql(vec3.zero())) {
            direction = direction.norm().scale(@floatCast(speed));
            self.position = self.position.add(direction);
            self.update_view();
            self.update_vp();
        }
    }

    pub fn on_resize(self: *Camera, width: f32, height: f32) void {
        self.width = width;
        self.height = height;
        self.update_projection();
        self.update_vp();
    }

    pub fn on_scroll(self: *Camera, y: f32) void {
        if (y > 0) {
            self.zoom += 0.1;
        } else {
            self.zoom -= 0.1;
        }

        //clamp zoom between 0.1 and 10
        self.zoom = @min(@max(self.zoom, 0.1), 10.0);

        self.update_view();
        self.update_vp();
    }

    fn update_view(self: *Camera) void {
        const scale_factor = 32.0 * self.zoom;

        var view = mat4.identity();
        view = view.translate(self.position);
        view = view.scale(vec3.new(scale_factor, scale_factor, 1));

        self.view_matrix = view;
    }

    fn update_projection(self: *Camera) void {
        const w = self.width / 2;
        const h = self.height / 2;
        const projection_matrix = mat4.orthographic(-w, w, h, -h, -1, 1);
        self.projection_matrix = projection_matrix;
    }

    fn update_vp(self: *Camera) void {
        self.vp_matrix = mat4.mul(self.projection_matrix, self.view_matrix);
    }
};
