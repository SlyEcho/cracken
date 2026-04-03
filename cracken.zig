const std = @import("std");
const win32 = @import("win32.zig");
const app = @import("app.zig");
const mainwindow = @import("mainwindow.zig");

pub fn main() !void {
    app.instance = @ptrCast(win32.GetModuleHandleW(null));
    app.allocator = std.heap.c_allocator;

    win32.InitCommonControls();

    const mw = mainwindow.create();
    mw.show();

    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (win32.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }
}
