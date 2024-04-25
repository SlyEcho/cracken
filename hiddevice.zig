const std = @import("std");

const HidDevice = extern struct {
    product_id: u16,
    vendor_id: u16,
    serial: [128:0]u16,
    path: [*:0]u16,
};

pub var allocator: std.mem.Allocator = undefined;

pub export fn HidDevice_create(vid: u16, pid: u16, path: [*:0]const u16) callconv(.C) *HidDevice {
    const d = allocator.create(HidDevice) catch {
        unreachable;
    };

    d.path = allocator.dupeZ(u16, std.mem.span(path)) catch {
        unreachable;
    };

    d.vendor_id = vid;
    d.product_id = pid;
    d.serial[0] = 0;
    return d;
}

pub export fn HidDevice_delete(h: *HidDevice) callconv(.C) void {
    allocator.free(std.mem.span(h.path));
    allocator.destroy(h);
}
