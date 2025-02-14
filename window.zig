const std = @import("std");
const app = @import("app.zig");
const w = @import("win32.zig");

pub const Window = extern struct {
    const Self = @This();

    const FnWindow = *const fn (w: *Window) callconv(.C) void;
    const FnWindowCmd = *const fn (w: *Window, id: i32) callconv(.C) void;
    const FnWindowColor = *const fn (w: *Window, hdc: w.HDC, ctrl: w.HWND) callconv(.C) w.HANDLE;

    const WindowClass = extern struct {
        name: [*c]const u16,
        registered: bool,
        style: i32,
        background: ?w.HANDLE,

        created: FnWindow,
        paint: FnWindow,
        static_color: FnWindowColor,
        destroyed: FnWindow,
        resize: FnWindow,
        dpi: FnWindow,

        command: FnWindowCmd,
        clicked: FnWindowCmd,
        select: FnWindowCmd,
        timer: FnWindowCmd,
    };

    class: *const WindowClass,
    hwnd: w.HWND,
    width: i32,
    height: i32,
    dpi: i32,
    content_height: i32,

    fn scale(self: *Self, s: i32) callconv(.C) i32 {
        return s * @divFloor(self.dpi, 96);
    }

    fn unscale(self: *Self, s: i32) callconv(.C) i32 {
        return s * @divFloor(96, self.dpi);
    }

    fn show(self: *Self) callconv(.C) void {
        _ = w.ShowWindow(self.hwnd, w.SW_SHOWDEFAULT);
    }

    fn rescale(self: *Self, x: i32, y: i32, width: i32, height: i32) callconv(.C) void {
        var size: w.RECT = undefined;
        if (w.GetWindowRect(self.hwnd, &size) == w.FALSE) return;

        if (x != -1) size.left = self.scale(x);
        if (y != -1) size.top = self.scale(y);

        _ = w.SetWindowPos(
            self.hwnd,
            null,
            size.left,
            size.top,
            self.scale(width),
            self.scale(height),
            w.SWP_NOZORDER | w.SWP_NOACTIVATE,
        );
    }
};

comptime {
    @export(Window.show, .{ .name = "Window_show", .linkage = .strong });
    @export(Window.scale, .{ .name = "Window_scale", .linkage = .strong });
    @export(Window.rescale, .{ .name = "Window_rescale", .linkage = .strong });
    @export(Window.unscale, .{ .name = "Window_unscale", .linkage = .strong });
}
