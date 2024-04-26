const std = @import("std");
const win32 = @import("win32.zig");
const layout = @import("layout.zig");
const hiddevice = @import("hiddevice.zig");
const list = @import("list.zig");
const denu = @import("deviceenumerator.zig");

extern var App_instance: win32.HINSTANCE;
const Window = opaque {};
extern fn MainWindow_create() callconv(.C) *Window;
extern fn Window_show(window: *Window, show: i32) callconv(.C) void;

pub fn main() !void {
    _ = layout; // force layout to build and link

    hiddevice.allocator = std.heap.c_allocator;
    list.allocator = std.heap.c_allocator;
    denu.allocator = std.heap.c_allocator;

    App_instance = @as(win32.HINSTANCE, @ptrCast(win32.GetModuleHandleW(null)));
    win32.InitCommonControls();

    const mw: *Window = MainWindow_create();
    Window_show(mw, 1);

    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (win32.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }
}
