const app = @import("app.zig");

fn xmalloc(size: usize) callconv(.C) [*]align(8) u8 {
    var slice = app.allocator.alignedAlloc(u8, 8, size) catch unreachable;
    return @ptrCast(&slice[0]);
}

fn xcalloc(count: usize, size: usize) callconv(.C) [*]align(8) u8 {
    var slice = app.allocator.alignedAlloc(u8, 8, count * size) catch unreachable;
    @memset(slice, 0);
    return @ptrCast(&slice[0]);
}

fn xfree(p: [*]u8, size: usize) callconv(.C) void {
    app.allocator.free(p[0..size]);
}

comptime {
    @export(xmalloc, .{ .name = "xmalloc", .linkage = .strong });
    @export(xcalloc, .{ .name = "xcalloc", .linkage = .strong });
    @export(xfree, .{ .name = "xfree", .linkage = .strong });
}
