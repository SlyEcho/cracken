const std = @import("std");
const app = @import("app.zig");

pub const HidDevice = @This();

product_id: u16,
vendor_id: u16,
serial: [:0]u16,
path: [:0]u16,

pub fn init(vid: u16, pid: u16, path: []const u16, serial: []const u16) !*HidDevice {
    const d = try app.allocator.create(HidDevice);
    d.path = try app.allocator.dupeZ(u16, path);
    d.serial = try app.allocator.dupeZ(u16, serial);
    d.vendor_id = vid;
    d.product_id = pid;
    return d;
}

pub fn deinit(h: *HidDevice) void {
    app.allocator.free(h.path);
    app.allocator.free(h.serial);
    app.allocator.destroy(h);
}
