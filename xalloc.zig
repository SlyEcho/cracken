const app = @import("app.zig");

pub fn xmalloc(size: usize) [*]align(8) u8 {
    var slice = app.allocator.alignedAlloc(u8, .@"8", size) catch unreachable;
    @memset(slice, 0);
    return @ptrCast(&slice[0]);
}

pub fn xfree(p: [*]u8, size: usize) void {
    app.allocator.free(p[0..size]);
}

