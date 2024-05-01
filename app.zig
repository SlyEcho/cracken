const std = @import("std");
const win32 = @import("win32.zig");

pub var instance: win32.HINSTANCE = undefined;
pub var allocator: std.mem.Allocator = undefined;

comptime {
    @export(instance, .{ .name = "App_instance", .linkage = .strong });
}
