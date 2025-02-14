const std = @import("std");
const win32 = @import("win32.zig");
const app = @import("app.zig");
const kraken = @import("kraken.zig");
const layout = @import("layout.zig");
const window = @import("window.zig");
const xalloc = @import("xalloc.zig");

const Window = opaque {};
extern fn MainWindow_create() callconv(.C) *Window;
extern fn Window_show(window: *Window) callconv(.C) void;

pub fn main() !void {
    _ = kraken;
    _ = layout;
    _ = window;
    _ = xalloc;

    app.instance = @ptrCast(win32.GetModuleHandleW(null));
    app.allocator = std.heap.c_allocator;

    win32.InitCommonControls();

    const mw: *Window = MainWindow_create();
    Window_show(mw);

    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (win32.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }
}
