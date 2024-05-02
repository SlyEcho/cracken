const std = @import("std");
const app = @import("app.zig");

pub const HidDevice = extern struct {
    product_id: u16,
    vendor_id: u16,
    serial: [128]u16,
    path: [*:0]u16,

    pub fn init(vid: u16, pid: u16, path: [*:0]const u16) callconv(.C) *HidDevice {
        const d = app.allocator.create(HidDevice) catch unreachable;
        d.path = app.allocator.dupeZ(u16, std.mem.span(path)) catch unreachable;
        d.vendor_id = vid;
        d.product_id = pid;
        d.serial[0] = 0;
        return d;
    }

    pub fn deinit(h: *HidDevice) callconv(.C) void {
        app.allocator.free(std.mem.span(h.path));
        app.allocator.destroy(h);
    }
};

comptime {
    @export(HidDevice.init, .{ .name = "HidDevice_create", .linkage = .strong });
    @export(HidDevice.deinit, .{ .name = "HidDevice_delete", .linkage = .strong });
}
