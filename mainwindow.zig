const std = @import("std");
const app = @import("app.zig");
const List = @import("list.zig");
const w = @import("win32.zig");
const window = @import("window.zig");

const Kraken = opaque {};
extern fn Kraken_update(k: *Kraken) callconv(.c) void;
extern fn Kraken_get_krakens() callconv(.c) *List.ContainerType;

const KrakenWidget = extern struct {
    base: window.Window,
    kraken: ?*anyopaque,
};
extern fn KrakenWidget_create(parent: *window.Window, kraken: *Kraken) callconv(.c) *KrakenWidget;
extern fn KrakenWidget_update(kw: *KrakenWidget) callconv(.c) void;

extern fn Window_init(wnd: *window.Window, parent: ?*window.Window, title: [*:0]const u16) callconv(.c) void;
extern fn Window_rescale(wnd: *window.Window, x: i32, y: i32, width: i32, height: i32) callconv(.c) void;
extern fn Window_scale(wnd: *window.Window, dimension: i32) callconv(.c) i32;
extern fn Window_unscale(wnd: *window.Window, dimension: i32) callconv(.c) i32;
extern fn Window_update_scroll(wnd: *window.Window) callconv(.c) void;

pub const MainWindow = extern struct {
    base: window.Window,
};

const PrivateMainWindow = extern struct {
    public: MainWindow,
    font: ?w.HFONT,
    no_devices: ?w.HWND,
    krakens: *List.ContainerType,
    widgets: ?[*]*KrakenWidget,
    widget_count: usize,
};

const ID_UPDATE = 0x100;

fn selfFromBase(base: *window.Window) *PrivateMainWindow {
    const pub_main: *MainWindow = @fieldParentPtr("base", base);
    return @fieldParentPtr("public", pub_main);
}

fn setWindowFont(hwnd: w.HWND, font: ?w.HFONT, redraw: bool) void {
    const hfont = if (font) |f| @intFromPtr(f) else 0;
    _ = w.SendMessageW(hwnd, w.WM_SETFONT, hfont, @intFromBool(redraw));
}

fn update(self: *PrivateMainWindow) void {
    var i: usize = 0;
    while (i < List.length(self.krakens)) : (i += 1) {
        const k: *Kraken = @ptrCast(@alignCast(List.get(self.krakens, i).?));
        Kraken_update(k);
    }

    i = 0;
    while (i < self.widget_count) : (i += 1) {
        KrakenWidget_update(self.widgets.?[i]);
    }

    _ = w.InvalidateRect(self.public.base.hwnd, null, w.TRUE);
    _ = w.UpdateWindow(self.public.base.hwnd);
}

fn loadAssets(self: *PrivateMainWindow, reload: bool) void {
    if (self.no_devices) |no_devices| {
        if (reload) {
            if (self.font) |font| {
                _ = w.DeleteObject(@ptrCast(font));
            }
            self.font = null;
        }

        if (self.font == null) {
            self.font = w.createFont(
                Window_scale(&self.public.base, 16),
                std.unicode.utf8ToUtf16LeStringLiteral("Segoe UI"),
                .{},
            );
        }

        setWindowFont(no_devices, self.font, true);
        _ = w.InvalidateRect(self.public.base.hwnd, null, w.TRUE);
    }
}

fn destroy(base: *window.Window) callconv(.c) void {
    _ = selfFromBase(base);
    w.PostQuitMessage(0);
}

fn resize(base: *window.Window) callconv(.c) void {
    const self = selfFromBase(base);

    self.public.base.content_height = 0;

    var i: usize = 0;
    while (i < self.widget_count) : (i += 1) {
        const y: i32 = @intCast(10 + i * 150);
        Window_rescale(
            &self.widgets.?[i].base,
            10,
            y,
            Window_unscale(&self.public.base, self.public.base.width) - 20,
            140,
        );
        self.public.base.content_height += Window_scale(&self.public.base, 150);
    }

    if (self.no_devices) |no_devices| {
        _ = w.MoveWindow(no_devices, 0, 0, self.public.base.width, self.public.base.height, w.TRUE);
    }

    loadAssets(self, false);
}

fn dpi(base: *window.Window) callconv(.c) void {
    loadAssets(selfFromBase(base), true);
}

fn created(base: *window.Window) callconv(.c) void {
    const self = selfFromBase(base);

    self.krakens = Kraken_get_krakens();
    update(self);

    _ = w.SetTimer(self.public.base.hwnd, ID_UPDATE, 2000, null);
    self.widget_count = List.length(self.krakens);

    if (self.widget_count > 0) {
        const widgets = app.allocator.alloc(*KrakenWidget, self.widget_count) catch unreachable;
        self.widgets = widgets.ptr;

        var i: usize = 0;
        while (i < self.widget_count) : (i += 1) {
            const k: *Kraken = @ptrCast(@alignCast(List.get(self.krakens, i).?));
            const kw = KrakenWidget_create(&self.public.base, k);
            self.widgets.?[i] = kw;
            KrakenWidget_update(kw);
        }
    }

    if (self.widget_count == 0) {
        self.no_devices = w.createWindow(
            std.unicode.utf8ToUtf16LeStringLiteral("Static"),
            std.unicode.utf8ToUtf16LeStringLiteral("No devices found"),
            .{
                .style = w.SS_CENTER | w.SS_CENTERIMAGE | w.WS_CHILD | w.WS_VISIBLE,
                .x = 0,
                .y = 0,
                .width = 0,
                .height = 0,
                .parent = self.public.base.hwnd,
                .instance = app.instance,
            },
        );
    }

    resize(base);
    Window_update_scroll(&self.public.base);
}

fn command(base: *window.Window, id: i32) callconv(.c) bool {
    const self = selfFromBase(base);

    if (id == ID_UPDATE) {
        update(self);
        return true;
    }

    return false;
}

fn staticColor(base: *window.Window, hdc: w.HDC, _: w.HWND) callconv(.c) ?w.HBRUSH {
    _ = selfFromBase(base);
    _ = w.SetBkMode(hdc, w.TRANSPARENT);
    return w.GetSysColorBrush(w.COLOR_WINDOW);
}

var crackenClass = window.Window.WindowClass{
    .name = std.unicode.utf8ToUtf16LeStringLiteral("MainWindowClass"),
    .registered = false,
    .style = w.WS_OVERLAPPEDWINDOW | w.WS_VSCROLL,
    .background = null,
    .created = created,
    .paint = null,
    .static_color = staticColor,
    .destroyed = destroy,
    .resize = resize,
    .dpi = dpi,
    .command = null,
    .clicked = command,
    .select = null,
    .timer = command,
};

fn createExport() callconv(.c) *window.Window {
    const self = app.allocator.create(PrivateMainWindow) catch unreachable;
    self.* = .{
        .public = .{ .base = undefined },
        .font = null,
        .no_devices = null,
        .krakens = undefined,
        .widgets = null,
        .widget_count = 0,
    };

    if (!crackenClass.registered) {
        crackenClass.background = w.GetSysColorBrush(w.COLOR_WINDOW);
    }

    self.public.base.class = &crackenClass;
    Window_init(&self.public.base, null, std.unicode.utf8ToUtf16LeStringLiteral("Cracken"));
    Window_rescale(&self.public.base, -1, -1, 300, 200);
    return &self.public.base;
}

comptime {
    @export(&createExport, .{ .name = "MainWindow_create", .linkage = .strong });
}
