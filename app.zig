const std = @import("std");
const builtin = @import("builtin");
const win32 = @import("win32.zig");

pub var instance: win32.HINSTANCE = undefined;
pub var allocator: std.mem.Allocator = undefined;
pub const is_debug = builtin.mode == .Debug;

comptime {
    @export(&instance, .{ .name = "App_instance", .linkage = .strong });
}
