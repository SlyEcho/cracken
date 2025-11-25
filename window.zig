const std = @import("std");
const app = @import("app.zig");
const w = @import("win32.zig");

pub const Window = extern struct {
    const Self = @This();

    const FnWindow = *const fn (w: *Window) callconv(.c) void;
    const FnWindowCmd = *const fn (w: *Window, id: i32) callconv(.c) bool;
    const FnWindowColor = *const fn (w: *Window, hdc: w.HDC, ctrl: w.HWND) callconv(.c) ?w.HBRUSH;

    const WindowClass = extern struct {
        name: [*c]const u16,
        registered: bool,
        style: i32,
        background: ?w.HBRUSH,

        created: ?FnWindow,
        paint: ?FnWindow,
        static_color: ?FnWindowColor,
        destroyed: ?FnWindow,
        resize: ?FnWindow,
        dpi: ?FnWindow,

        command: ?FnWindowCmd,
        clicked: ?FnWindowCmd,
        select: ?FnWindowCmd,
        timer: ?FnWindowCmd,
    };

    class: *WindowClass,
    hwnd: w.HWND,
    width: i32,
    height: i32,
    dpi: i32,
    content_height: i32,

    fn scale(self: *Self, s: i32) callconv(.c) i32 {
        return @divFloor(s * self.dpi, 96);
    }

    fn unscale(self: *Self, s: i32) callconv(.c) i32 {
        return @divFloor(s * 96, self.dpi);
    }

    fn show(self: *Self) callconv(.c) void {
        _ = w.ShowWindow(self.hwnd, w.SW_SHOWDEFAULT);
    }

    fn rescale(self: *Self, x: i32, y: i32, width: i32, height: i32) callconv(.c) void {
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

    fn update_scroll(self: *Self) callconv(.c) void {
        var si: w.SCROLLINFO = .{ .fMask = w.SIF_POS };

        _ = w.GetScrollInfo(self.hwnd, w.SB_VERT, &si);
        si.fMask = w.SIF_RANGE | w.SIF_PAGE;
        si.nMin = 0;
        si.nMax = self.content_height;
        si.nPage = @intCast(self.height);
        _ = w.SetScrollInfo(self.hwnd, w.SB_VERT, &si, w.TRUE);

        if (si.nPos > 0 and si.nPos > self.content_height - self.height) {
            _ = w.ScrollWindow(self.hwnd, 0, si.nPos - (self.content_height - self.height), null, null);
            si.nPos = self.content_height - self.height;
        }
    }

    fn handle_resize(self: *Self, msg: w.UINT, wParam: w.WPARAM, lParam: w.LPARAM) bool {
        switch (msg) {
            w.WM_SIZE => {
                self.width = w.LOWORD(lParam);
                self.height = w.HIWORD(lParam);
            },
            w.WM_DPICHANGED_BEFOREPARENT => {
                self.dpi = @intCast(w.GetDpiForWindow(self.hwnd));
            },
            w.WM_DPICHANGED => {
                self.dpi = w.HIWORD(wParam);
                const r: *w.RECT = @ptrFromInt(@as(usize, @bitCast(lParam)));
                _ = w.SetWindowPos(
                    self.hwnd,
                    null,
                    r.left,
                    r.top,
                    r.right - r.left,
                    r.bottom - r.top,
                    w.SWP_NOZORDER | w.SWP_NOACTIVATE,
                );
            },
            else => return false,
        }
        return true;
    }

    fn handle_colors(self: *Self, msg: w.UINT, wParam: w.WPARAM, lParam: w.LPARAM) ?w.HBRUSH {
        switch (msg) {
            w.WM_CTLCOLORSTATIC => {
                if (self.class.static_color) |handler| {
                    const hdc: w.HDC = @ptrFromInt(wParam);
                    const hwnd: w.HWND = @ptrFromInt(@as(usize, @bitCast(lParam)));
                    return handler(self, hdc, hwnd);
                }
            },
            else => {},
        }
        return null;
    }

    fn handle_vscroll(self: *Self, msg: w.UINT, wParam: w.WPARAM, _: w.LPARAM) bool {
        if ((self.class.style & w.WS_VSCROLL) == 0) return false;

        switch (msg) {
            w.WM_DPICHANGED, w.WM_SIZE => {
                self.update_scroll();
            },
            w.WM_MOUSEWHEEL => {
                var scrollLines: i32 = 3;
                _ = w.SystemParametersInfoW(w.SPI_GETWHEELSCROLLLINES, 0, &scrollLines, 0);
                const zDelta = w.GET_WHEEL_DELTA_WPARAM(wParam);
                const turn = @divTrunc(zDelta, w.WHEEL_DELTA);

                var i: i32 = 0;
                while (i < scrollLines) : (i += 1) {
                    _ = w.SendMessageW(self.hwnd, w.WM_VSCROLL, w.MAKELONG(if (turn > 0) w.SB_LINEUP else w.SB_LINEDOWN, 0), 0);
                }
            },
            w.WM_VSCROLL => {
                var si = w.SCROLLINFO{
                    .cbSize = @sizeOf(w.SCROLLINFO),
                    .fMask = w.SIF_POS | w.SIF_TRACKPOS,
                };
                _ = w.GetScrollInfo(self.hwnd, w.SB_VERT, &si);

                const oldpos = si.nPos;
                switch (w.LOWORD(wParam)) {
                    w.SB_TOP => si.nPos = 0,
                    w.SB_BOTTOM => si.nPos = self.content_height,
                    w.SB_LINEUP => si.nPos -= self.scale(25),
                    w.SB_LINEDOWN => si.nPos += self.scale(25),
                    w.SB_PAGEUP => si.nPos -= self.height,
                    w.SB_PAGEDOWN => si.nPos += self.height,
                    w.SB_THUMBTRACK => si.nPos = si.nTrackPos,
                    else => {},
                }

                si.fMask = w.SIF_POS;
                _ = w.SetScrollInfo(self.hwnd, w.SB_VERT, &si, w.TRUE);
                _ = w.GetScrollInfo(self.hwnd, w.SB_VERT, &si);

                if (si.nPos != oldpos) {
                    _ = w.ScrollWindow(self.hwnd, 0, oldpos - si.nPos, null, null);
                }
            },
            else => return false,
        }

        return true;
    }

    fn handle_virtual(self: *Self, msg: w.UINT, wParam: w.WPARAM, _: w.LPARAM) bool {
        switch (msg) {
            w.WM_CREATE => {
                if (self.class.created) |handler| {
                    handler(self);
                    return true;
                }
            },
            w.WM_DESTROY => {
                if (self.class.destroyed) |handler| {
                    handler(self);
                    return true;
                }
            },
            w.WM_PAINT => {
                if (self.class.paint) |handler| {
                    handler(self);
                    return true;
                }
            },
            w.WM_DPICHANGED_BEFOREPARENT, w.WM_DPICHANGED => {
                if (self.class.dpi) |handler| {
                    handler(self);
                    return true;
                }
            },
            w.WM_SIZE => {
                if (self.class.resize) |handler| {
                    handler(self);
                    return true;
                }
            },
            w.WM_COMMAND => {
                const id = w.LOWORD(wParam);
                const cmd = w.HIWORD(wParam);
                if (cmd == w.BN_CLICKED) {
                    if (self.class.clicked) |handler| {
                        if (handler(self, @intCast(id))) return true;
                    }
                }
                if (cmd == w.CBN_SELCHANGE) {
                    if (self.class.select) |handler| {
                        if (handler(self, @intCast(id))) return true;
                    }
                }
                if (self.class.command) |handler| {
                    if (handler(self, @intCast(id))) return true;
                }
            },
            w.WM_TIMER => {
                if (self.class.timer) |handler| {
                    if (handler(self, @intCast(wParam))) return true;
                }
            },
            else => {},
        }
        return false;
    }

    fn window_proc(hwnd: w.HWND, msg: w.UINT, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.winapi) w.LRESULT {
        var self: ?*Window = null;

        if (msg == w.WM_CREATE) {
            const pCreate: *w.CREATESTRUCTW = @ptrFromInt(@as(usize, @bitCast(lParam)));
            self = @ptrCast(@alignCast(pCreate.lpCreateParams));
            if (self) |s| {
                s.hwnd = hwnd;
                _ = w.SetWindowLongPtrW(hwnd, w.GWLP_USERDATA, @bitCast(@intFromPtr(s)));
            }
        } else {
            const ptr = w.GetWindowLongPtrW(hwnd, w.GWLP_USERDATA);
            if (ptr != 0) {
                self = @ptrFromInt(@as(usize, @bitCast(ptr)));
            }
        }

        if (self) |s| {
            if (s.handle_colors(msg, wParam, lParam)) |brush| {
                return @bitCast(@intFromPtr(brush));
            }

            var handled = false;
            handled |= s.handle_resize(msg, wParam, lParam);
            handled |= s.handle_virtual(msg, wParam, lParam);
            handled |= s.handle_vscroll(msg, wParam, lParam);

            if (handled) {
                return 0;
            }
        }

        return w.DefWindowProcW(hwnd, msg, wParam, lParam);
    }

    pub fn init(self: *Self, parent: ?*Window, title: [*:0]const u16) callconv(.c) void {
        if (!self.class.registered) {
            const wc = w.WNDCLASSW{
                .style = w.CS_HREDRAW | w.CS_VREDRAW,
                .lpfnWndProc = window_proc,
                .cbClsExtra = 0,
                .cbWndExtra = 0,
                .hInstance = app.instance,
                .hIcon = null,
                .hCursor = w.LoadCursorW(null, w.IDC_ARROW),
                .hbrBackground = self.class.background,
                .lpszMenuName = null,
                .lpszClassName = self.class.name,
            };

            _ = w.RegisterClassW(&wc);
            self.class.registered = true;
        }

        self.content_height = 0;
        self.dpi = @intCast(w.GetDpiForSystem());
        self.width = 0;
        self.height = 0;

        const parent_hwnd = if (parent) |p| p.hwnd else null;

        const hwnd = w.CreateWindowExW(
            0,
            self.class.name,
            title,
            @bitCast(self.class.style),
            w.CW_USEDEFAULT,
            w.CW_USEDEFAULT,
            0,
            0,
            parent_hwnd,
            null,
            app.instance,
            self,
        );

        var r: w.RECT = undefined;
        _ = w.GetClientRect(hwnd, &r);
        self.width = r.right;
        self.height = r.bottom;
        self.dpi = @intCast(w.GetDpiForWindow(hwnd));
    }
};

comptime {
    @export(&Window.init, .{ .name = "Window_init", .linkage = .strong });
    @export(&Window.show, .{ .name = "Window_show", .linkage = .strong });
    @export(&Window.scale, .{ .name = "Window_scale", .linkage = .strong });
    @export(&Window.rescale, .{ .name = "Window_rescale", .linkage = .strong });
    @export(&Window.unscale, .{ .name = "Window_unscale", .linkage = .strong });
    @export(&Window.update_scroll, .{ .name = "Window_update_scroll", .linkage = .strong });
}
