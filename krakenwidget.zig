const std = @import("std");
const app = @import("app.zig");
const curves = @import("curve.zig");
const kraken_mod = @import("kraken.zig");
const layout = @import("layout.zig");
const w = @import("win32.zig");
const window = @import("window.zig");

const Kraken = kraken_mod;
const DeviceInfo = kraken_mod.DeviceInfo;
const Curve = curves.Curve;
const LayoutCell = layout.LayoutCell;

extern fn Window_init(wnd: *window.Window, parent: ?*window.Window, title: [*:0]const u16) callconv(.c) void;
extern fn Window_scale(wnd: *window.Window, dimension: i32) callconv(.c) i32;

pub const KrakenWidget = extern struct {
    base: window.Window,
    kraken: *Kraken,
};

const Controls = extern struct {
    device: ?w.HWND,
    fan: ?w.HWND,
    temp: ?w.HWND,
    pump: ?w.HWND,
};

const PrivateKrakenWidget = extern struct {
    public: KrakenWidget,
    font: ?w.HFONT,
    bold_font: ?w.HFONT,
    big_font: ?w.HFONT,
    pump: ?w.HWND,
    fan: ?w.HWND,
    labels: Controls,
    values: Controls,
};

const ID_PUMP = 0x1001;
const ID_FAN = 0x1002;

fn selfFromBase(base: *window.Window) *PrivateKrakenWidget {
    const pub_kw: *KrakenWidget = @fieldParentPtr("base", base);
    return @fieldParentPtr("public", pub_kw);
}

fn setWindowFont(hwnd: ?w.HWND, font: ?w.HFONT, redraw: bool) void {
    if (hwnd == null) return;
    const hfont = if (font) |f| @intFromPtr(f) else 0;
    _ = w.SendMessageW(hwnd.?, w.WM_SETFONT, hfont, @intFromBool(redraw));
}

fn comboBoxAddString(hwnd: w.HWND, text: [*:0]const u16) void {
    _ = w.SendMessageW(hwnd, w.CB_ADDSTRING, 0, @bitCast(@as(isize, @intCast(@intFromPtr(text)))));
}

fn comboBoxGetCurSel(hwnd: w.HWND) i32 {
    return @intCast(@as(isize, @bitCast(w.SendMessageW(hwnd, w.CB_GETCURSEL, 0, 0))));
}

fn formatLabel(comptime fmt: []const u8, args: anytype) [:0]u16 {
    var utf8_buf: [64]u8 = undefined;
    const utf8 = std.fmt.bufPrint(&utf8_buf, fmt, args) catch unreachable;
    return std.unicode.utf8ToUtf16LeAllocZ(app.allocator, utf8) catch unreachable;
}

fn updateExport(this: *KrakenWidget) callconv(.c) void {
    const info: *const DeviceInfo = kraken_mod.getInfo(this.kraken) orelse return;

    const temp = formatLabel("{d:.1} °C", .{info.temp_c});
    defer app.allocator.free(temp);
    _ = w.SetWindowTextW(selfFromBase(&this.base).values.temp.?, temp.ptr);

    const fan = formatLabel("{d:.0} rpm", .{info.fan_rpm});
    defer app.allocator.free(fan);
    _ = w.SetWindowTextW(selfFromBase(&this.base).values.fan.?, fan.ptr);

    const pump = formatLabel("{d:.0} rpm", .{info.pump_rpm});
    defer app.allocator.free(pump);
    _ = w.SetWindowTextW(selfFromBase(&this.base).values.pump.?, pump.ptr);
}

fn position(self: *PrivateKrakenWidget) void {
    if (self.pump == null or self.fan == null) return;

    const m = Window_scale(&self.public.base, 5);
    const h = Window_scale(&self.public.base, 20);

    var c_lab_device = LayoutCell{ .text = null, .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.labels.device };
    var c_lab_temp = LayoutCell{ .text = null, .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.labels.temp };
    var c_lab_fan = LayoutCell{ .text = null, .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.labels.fan };
    var c_lab_pump = LayoutCell{ .text = null, .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.labels.pump };

    var c_val_device = LayoutCell{ .text = null, .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.values.device };
    var c_val_temp = LayoutCell{ .text = @constCast(std.unicode.utf8ToUtf16LeStringLiteral("99.9 °C")), .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.values.temp };
    var c_val_fan = LayoutCell{ .text = @constCast(std.unicode.utf8ToUtf16LeStringLiteral("9999 rpm")), .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.values.fan };
    var c_val_pump = LayoutCell{ .text = @constCast(std.unicode.utf8ToUtf16LeStringLiteral("9999 rpm")), .font = null, .height = 0, .width = 0, .ascender = 0, .x = 0, .y = 0, .control = self.values.pump };

    var cells = [_]*LayoutCell{
        &c_lab_device, &c_val_device,
        &c_lab_temp, &c_val_temp,
        &c_lab_fan, &c_val_fan,
        &c_lab_pump, &c_val_pump,
    };

    const hdc = w.GetDC(self.public.base.hwnd) orelse return;
    defer _ = w.ReleaseDC(self.public.base.hwnd, hdc);

    layout.layout(hdc, 0, 0, 4, 2, &cells, Window_scale(&self.public.base, 5));

    const pump_y = c_val_pump.y + c_val_pump.ascender;
    const fan_y = c_val_fan.y + c_val_fan.ascender;
    const val_w = @max(@max(c_val_pump.x + c_val_pump.width, c_val_fan.x + c_val_fan.width), c_val_temp.x + c_val_temp.width);

    _ = w.MoveWindow(self.pump.?, val_w + m, pump_y - h, self.public.base.width - val_w - m, h, w.TRUE);
    _ = w.MoveWindow(self.fan.?, val_w + m, fan_y - h, self.public.base.width - val_w - m, h, w.TRUE);
}

fn loadAssets(self: *PrivateKrakenWidget, reload: bool) void {
    if (reload) {
        if (self.font) |font| _ = w.DeleteObject(@ptrCast(font));
        if (self.bold_font) |font| _ = w.DeleteObject(@ptrCast(font));
        if (self.big_font) |font| _ = w.DeleteObject(@ptrCast(font));
        self.font = null;
        self.bold_font = null;
        self.big_font = null;
    }

    if (self.font == null) {
        self.font = w.createFont(
            Window_scale(&self.public.base, 16),
            std.unicode.utf8ToUtf16LeStringLiteral("Segoe UI"),
            .{},
        );
    }

    if (self.bold_font == null) {
        self.bold_font = w.createFont(
            Window_scale(&self.public.base, 16),
            std.unicode.utf8ToUtf16LeStringLiteral("Segoe UI"),
            .{ .weight = w.FW_BOLD },
        );
    }

    if (self.big_font == null) {
        self.big_font = w.createFont(
            Window_scale(&self.public.base, 36),
            std.unicode.utf8ToUtf16LeStringLiteral("Arial"),
            .{ .weight = w.FW_BOLD },
        );
    }

    setWindowFont(self.pump, self.font, false);
    setWindowFont(self.fan, self.font, false);

    setWindowFont(self.labels.device, self.font, false);
    setWindowFont(self.labels.fan, self.font, false);
    setWindowFont(self.labels.pump, self.font, false);
    setWindowFont(self.labels.temp, self.font, false);

    setWindowFont(self.values.device, self.bold_font, false);
    setWindowFont(self.values.fan, self.big_font, false);
    setWindowFont(self.values.pump, self.big_font, false);
    setWindowFont(self.values.temp, self.big_font, false);

    _ = w.InvalidateRect(self.public.base.hwnd, null, w.TRUE);
}

fn staticColor(base: *window.Window, hdc: w.HDC, ctrl: w.HWND) callconv(.c) ?w.HBRUSH {
    const self = selfFromBase(base);

    if ((self.labels.device != null and ctrl == self.labels.device.?) or
        (self.labels.fan != null and ctrl == self.labels.fan.?) or
        (self.labels.pump != null and ctrl == self.labels.pump.?) or
        (self.labels.temp != null and ctrl == self.labels.temp.?)) {
        _ = w.SetTextColor(hdc, w.RGB(110, 110, 110));
    } else {
        _ = w.SetTextColor(hdc, w.RGB(30, 30, 30));
    }

    _ = w.SetBkMode(hdc, w.TRANSPARENT);
    return w.GetSysColorBrush(w.COLOR_WINDOW);
}

fn resize(base: *window.Window) callconv(.c) void {
    const self = selfFromBase(base);
    loadAssets(self, false);
    position(self);
}

fn created(base: *window.Window) callconv(.c) void {
    loadAssets(selfFromBase(base), false);
}

fn dpi(base: *window.Window) callconv(.c) void {
    loadAssets(selfFromBase(base), true);
}

fn selected(base: *window.Window, command: i32) callconv(.c) bool {
    const self = selfFromBase(base);

    if (command == ID_PUMP) {
        const i = comboBoxGetCurSel(self.pump.?);
        if (i != w.CB_ERR) {
            _ = w.SetCursor(w.LoadCursorW(null, w.IDC_APPSTARTING));
            const c = curves.pump_presets[@intCast(i)] orelse return true;
            kraken_mod.setPumpCurve(self.public.kraken, c);
        }
        return true;
    }

    if (command == ID_FAN) {
        const i = comboBoxGetCurSel(self.fan.?);
        if (i != w.CB_ERR) {
            _ = w.SetCursor(w.LoadCursorW(null, w.IDC_APPSTARTING));
            const c = curves.fan_presets[@intCast(i)] orelse return true;
            kraken_mod.setFanCurve(self.public.kraken, c);
        }
        return true;
    }

    return false;
}

var class = window.Window.WindowClass{
    .name = std.unicode.utf8ToUtf16LeStringLiteral("KrakenWidget"),
    .registered = false,
    .style = w.WS_CHILD | w.WS_VISIBLE,
    .background = null,
    .created = created,
    .paint = null,
    .static_color = staticColor,
    .destroyed = null,
    .resize = resize,
    .dpi = dpi,
    .command = null,
    .clicked = null,
    .select = selected,
    .timer = null,
};

fn makeStatic(parent: w.HWND, text: [*:0]const u16, style: u32) ?w.HWND {
    return w.createWindow(
        std.unicode.utf8ToUtf16LeStringLiteral("Static"),
        text,
        .{
            .style = style | w.WS_CHILD | w.WS_VISIBLE,
            .x = 0,
            .y = 0,
            .width = 0,
            .height = 0,
            .parent = parent,
            .instance = app.instance,
        },
    );
}

fn createExport(parent: *window.Window, kraken: *Kraken) callconv(.c) *KrakenWidget {
    const self = app.allocator.create(PrivateKrakenWidget) catch unreachable;
    self.* = .{
        .public = .{ .base = undefined, .kraken = kraken },
        .font = null,
        .bold_font = null,
        .big_font = null,
        .pump = null,
        .fan = null,
        .labels = .{ .device = null, .fan = null, .temp = null, .pump = null },
        .values = .{ .device = null, .fan = null, .temp = null, .pump = null },
    };

    self.public.base.class = &class;
    Window_init(&self.public.base, parent, std.unicode.utf8ToUtf16LeStringLiteral(""));

    self.pump = w.createWindow(
        std.unicode.utf8ToUtf16LeStringLiteral("ComboBox"),
        std.unicode.utf8ToUtf16LeStringLiteral(""),
        .{
            .style = w.CBS_DROPDOWNLIST | w.CBS_HASSTRINGS | w.WS_CHILD | w.WS_OVERLAPPED | w.WS_VISIBLE,
            .x = 0,
            .y = 0,
            .width = 0,
            .height = 1000,
            .parent = self.public.base.hwnd,
            .menu = @ptrFromInt(ID_PUMP),
            .instance = app.instance,
        },
    );

    self.fan = w.createWindow(
        std.unicode.utf8ToUtf16LeStringLiteral("ComboBox"),
        std.unicode.utf8ToUtf16LeStringLiteral(""),
        .{
            .style = w.CBS_DROPDOWNLIST | w.CBS_HASSTRINGS | w.WS_CHILD | w.WS_OVERLAPPED | w.WS_VISIBLE,
            .x = 0,
            .y = 0,
            .width = 0,
            .height = 1000,
            .parent = self.public.base.hwnd,
            .menu = @ptrFromInt(ID_FAN),
            .instance = app.instance,
        },
    );

    var i: usize = 0;
    while (curves.pump_presets[i] != null) : (i += 1) {
        comboBoxAddString(self.pump.?, curves.pump_presets[i].?.name[0..].ptr);
    }

    i = 0;
    while (curves.fan_presets[i] != null) : (i += 1) {
        comboBoxAddString(self.fan.?, curves.fan_presets[i].?.name[0..].ptr);
    }

    self.labels.fan = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral("Fan"), w.SS_RIGHT);
    self.labels.pump = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral("Pump"), w.SS_RIGHT);
    self.labels.device = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral("Device"), w.SS_RIGHT);
    self.labels.temp = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral("Temp"), w.SS_RIGHT);

    self.values.fan = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral(""), w.SS_LEFT);
    self.values.pump = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral(""), w.SS_LEFT);
    self.values.device = makeStatic(self.public.base.hwnd, kraken_mod.getIdent(kraken), w.SS_LEFT);
    self.values.temp = makeStatic(self.public.base.hwnd, std.unicode.utf8ToUtf16LeStringLiteral(""), w.SS_LEFT);

    loadAssets(self, false);
    position(self);

    return &self.public;
}

comptime {
    @export(&updateExport, .{ .name = "KrakenWidget_update", .linkage = .strong });
    @export(&createExport, .{ .name = "KrakenWidget_create", .linkage = .strong });
}
