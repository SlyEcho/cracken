const std = @import("std");
const app = @import("app.zig");
const hd = @import("hiddevice.zig");
const denu = @import("deviceenumerator.zig");
const List = @import("list.zig");
const win32 = @import("win32.zig");

const HANDLE = win32.HANDLE;

pub const Kraken = struct {
    device: *hd.HidDevice,
    reader: HANDLE,
    writer: ?HANDLE,
    ident: []u16,
    info: DeviceInfo,
};

pub const DeviceInfo = extern struct {
    temp_c: f64,
    fan_rpm: f64,
    pump_rpm: f64,
};

pub export fn Kraken_create(device: *hd.HidDevice) callconv(.C) *Kraken {
    var this = app.allocator.create(Kraken) catch unreachable;

    const serial = std.mem.sliceTo(&device.serial, 0);
    const ident = std.fmt.allocPrintZ(app.allocator, "X52 ({})", .{std.unicode.fmtUtf16Le(serial)}) catch unreachable;
    defer app.allocator.free(ident);
    this.ident = std.unicode.utf8ToUtf16LeAllocZ(app.allocator, ident) catch unreachable;
    this.device = device;
    this.reader = win32.CreateFileW(device.path, win32.GENERIC_READ, win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE, null, win32.OPEN_EXISTING, 0, null);
    this.writer = null;
    return this;
}

pub const FanOrPump = enum(u1) {
    FAN = 0,
    PUMP = 1,
};

pub fn Kraken_control(this: *Kraken, isSave: bool, fanOrpump: FanOrPump, levels: []const u8, interval: u32) void {
    if (this.writer == null) {
        this.writer = win32.CreateFileW(this.device.path, win32.GENERIC_WRITE, win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE, null, win32.OPEN_EXISTING, 0, null);
    }

    if (this.writer == null) {
        return;
    }

    var packet: [65]u8 = undefined;

    var i: usize = 0;
    while (i < levels.len) : (i += 1) {
        @memset(&packet, 0);

        packet[0] = 2;
        packet[1] = 77;
        packet[2] = @as(u8, @intFromBool(isSave)) * 128 + @as(u8, @intFromEnum(fanOrpump)) * 64 + @as(u8, @intCast(i));
        packet[3] = @as(u8, @intCast(i * interval));
        packet[4] = levels[i];

        var num: u32 = undefined;
        _ = win32.WriteFile(this.writer.?, @ptrCast(&packet), packet.len, &num, null);
    }
}

pub export fn Kraken_update(this: *Kraken) callconv(.C) void {
    var packet: [65]u8 = undefined;
    var num: u32 = undefined;
    if (win32.ReadFile(this.*.reader, @ptrCast(&packet), packet.len, &num, null) != 0) {
        this.info.temp_c = @as(f64, @floatFromInt(packet[1])) + @as(f64, @floatFromInt(packet[2])) * 0.1;
        this.info.fan_rpm = @as(f64, @floatFromInt(@as(u16, packet[3]) << 8 | packet[4]));
        this.info.pump_rpm = @as(f64, @floatFromInt(@as(u16, packet[5]) << 8 | packet[6]));
    }
}

pub export fn Kraken_get_ident(this: *const Kraken) callconv(.C) [*:0]const u16 {
    return @ptrCast(&this.ident[0]);
}

pub export fn Kraken_get_info(this: *const Kraken) callconv(.C) ?*const DeviceInfo {
    return &this.info;
}

const Curve = extern struct {
    name: [*:0]u16,
    length: u8,
    items: [*c]u8,
};

extern const Curve_fan_presets: [*]const *const Curve;
extern const Curve_pump_presets: [*]const *const Curve;

pub export fn Kraken_set_pump_curve(this: *Kraken, curve: *const Curve) callconv(.C) void {
    const interval = if (curve.length == 1) 0 else @divTrunc(100, curve.length - 1);
    Kraken_control(this, curve.length > 1, .PUMP, curve.items[0..curve.length], interval);
}

pub export fn Kraken_set_fan_curve(this: *Kraken, curve: *const Curve) callconv(.C) void {
    const interval = if (curve.length == 1) 0 else @divTrunc(100, curve.length - 1);
    Kraken_control(this, curve.length > 1, .FAN, curve.items[0..curve.length], interval);
}

pub export fn Kraken_delete(this: *Kraken) callconv(.C) void {
    _ = win32.CloseHandle(this.reader);
    if (this.writer != null) {
        _ = win32.CloseHandle(this.writer.?);
    }
    this.device.deinit();
    app.allocator.free(this.ident);
    app.allocator.destroy(this);
}

pub export fn Kraken_get_krakens() callconv(.C) *List.ContainerType {
    const hids = denu.enumerate();
    defer List.delete(hids, @ptrCast(&hd.HidDevice.deinit));

    const krakens = List.create(1);

    var i: usize = 0;
    while (i < List.length(hids)) : (i += 1) {
        const hid: *hd.HidDevice = @alignCast(@ptrCast(List.get(hids, i)));

        if (hid.vendor_id == 0x1e71 and hid.product_id == 0x170e) {
            const this = Kraken_create(hid);
            List.append(krakens, this);
            _ = List.set(hids, i, null);
        }
    }

    return krakens;
}
