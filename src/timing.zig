const st = @import("sokol").time;

var initialized = false;

/// initializes the timing system
pub fn setup() void {
    if (initialized) {
        return;
    }
    initialized = true;
    st.setup();
}

/// returns the time in seconds
pub fn now() f64 {
    const s = @as(f64, @floatFromInt(st.now())) / 1_000_000_000;
    return s;
}
