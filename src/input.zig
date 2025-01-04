const sapp = @import("sokol").app;
const std = @import("std");

pub const Codes = enum {
    W,
    A,
    S,
    D,
    Escape,
    Unknown,
    MAX,
};

pub const Input = struct {
    previousState: std.AutoHashMap(Codes, bool),
    currentState: std.AutoHashMap(Codes, bool),

    pub fn init(allocator: std.mem.Allocator) Input {
        const input = Input{
            .previousState = std.AutoHashMap(Codes, bool).init(allocator),
            .currentState = std.AutoHashMap(Codes, bool).init(allocator),
        };
        return input;
    }

    pub fn on_event(self: *Input, e: *const sapp.Event) void {
        const isDown = e.type == .KEY_DOWN;
        const key = map_key_to_code(e.key_code);

        self.currentState.put(key, isDown) catch {};
    }

    pub fn update(self: *Input) void {
        var iterator = self.currentState.iterator();
        while (iterator.next()) |key| {
            const code = key.key_ptr.*;
            const current = self.currentState.get(code) orelse false;
            self.previousState.put(code, current) catch {};
        }
    }

    pub fn is_down(self: *Input, code: Codes) bool {
        return self.currentState.get(code) orelse false;
    }

    pub fn is_up(self: *Input, code: Codes) bool {
        return !is_down(self, code);
    }

    pub fn was_pressed(self: *Input, code: Codes) bool {
        const current = self.currentState.get(code) orelse false;
        const previous = self.previousState.get(code) orelse false;
        return current and !previous;
    }

    pub fn was_released(self: *Input, code: Codes) bool {
        const wasDown = self.previousState.get(code) orelse false;
        const isUp = self.is_up(code);
        return wasDown and isUp;
    }

    pub fn deinit(self: *Input) void {
        self.previousState.deinit();
        self.currentState.deinit();
    }
};

fn map_key_to_code(key: sapp.Keycode) Codes {
    return switch (key) {
        sapp.Keycode.W => return Codes.W,
        sapp.Keycode.A => return Codes.A,
        sapp.Keycode.S => return Codes.S,
        sapp.Keycode.D => return Codes.D,
        sapp.Keycode.ESCAPE => return Codes.Escape,
        else => return Codes.Unknown,
    };
}
