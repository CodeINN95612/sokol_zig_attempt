const sg = @import("sokol").gfx;
const st = @import("sokol").time;

pub const global_state = struct {
    pub var pass_action: sg.PassAction = .{};

    pub fn now() f64 {
        const ms = @as(f64, @floatFromInt(st.now())) / 1_000_000_000;
        return ms;
    }
};
