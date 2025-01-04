const sg = @import("sokol").gfx;
const Input = @import("input.zig").Input;

pub const global_state = struct {
    pub var input: Input = undefined;

    pub var pass_action: sg.PassAction = .{};
    pub var bind: sg.Bindings = .{};
    pub var pipe: sg.Pipeline = .{};
};
