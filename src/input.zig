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

const InputState = struct {
    previousState: std.AutoHashMap(Codes, bool),
    currentState: std.AutoHashMap(Codes, bool),
    allocator: *std.mem.Allocator,

    var instance: ?*InputState = null;
};

pub fn setup(allocator: *std.mem.Allocator) !void {
    const state = try allocator.create(InputState);
    state.* = InputState{
        .previousState = std.AutoHashMap(Codes, bool).init(allocator.*),
        .currentState = std.AutoHashMap(Codes, bool).init(allocator.*),
        .allocator = allocator,
    };

    InputState.instance = state;
}

fn get() *InputState {
    if (InputState.instance) |instance| {
        return instance;
    }
    @panic("InputState not initialized");
}

pub fn shutdown() void {
    const state = get();
    state.previousState.deinit();
    state.currentState.deinit();
    state.allocator.destroy(state);
}

pub fn on_event(e: *const sapp.Event) void {
    const state = get();
    const isDown = e.type == .KEY_DOWN;
    const key = map_key_to_code(e.key_code);
    state.currentState.put(key, isDown) catch {};
}

pub fn is_down(code: Codes) bool {
    const state = get();
    return state.currentState.get(code) orelse false;
}

pub fn is_up(code: Codes) bool {
    return !is_down(code);
}

pub fn update() void {
    const state = get();
    var iterator = state.currentState.iterator();
    while (iterator.next()) |key| {
        const code = key.key_ptr.*;
        const current = state.currentState.get(code) orelse false;
        state.previousState.put(code, current) catch {};
    }
}

pub fn was_pressed(code: Codes) bool {
    const state = get();
    const current = state.currentState.get(code) orelse false;
    const previous = state.previousState.get(code) orelse false;
    return current and !previous;
}

pub fn was_released(code: Codes) bool {
    const state = get();
    const wasDown = state.previousState.get(code) orelse false;
    const isUp = !is_down(code);
    return wasDown and isUp;
}

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
