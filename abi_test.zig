const std = @import("std");
const w = @import("win32.zig");

const c = struct {
    pub extern var SIZEOF_HIDD_ATTRIBUTES: usize;
    pub extern var SIZEOF_SCROLLINFO: usize;
    pub extern var SIZEOF_SP_DEVICE_INTERFACE_DETAIL_DATA_W: usize;
};

test "HIDD_ATTRIBUTES" {
    try std.testing.expectEqual(c.SIZEOF_HIDD_ATTRIBUTES, (w.HIDD_ATTRIBUTES{}).cbSize);
}

test "SIZEOF_SP_DEVICE_INTERFACE_DETAIL_DATA_W" {
    try std.testing.expectEqual(c.SIZEOF_SP_DEVICE_INTERFACE_DETAIL_DATA_W, (w.SP_DEVICE_INTERFACE_DETAIL_DATA_W{}).cbSize);
}

test "SCROLLINFO" {
    try std.testing.expectEqual(c.SIZEOF_SCROLLINFO, (w.SCROLLINFO{}).cbSize);
}
