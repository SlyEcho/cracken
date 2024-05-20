const std = @import("std");
const app = @import("app.zig");
const HidDevice = @import("hiddevice.zig");
const DeviceEnumerator = @import("deviceenumerator.zig");
const List = @import("list.zig");
const win32 = @import("win32.zig");

pub const DeviceInfo = extern struct {
    temp_c: f64,
    fan_rpm: f64,
    pump_rpm: f64,
};

const Kraken = @This();

device: *HidDevice,
reader: win32.HANDLE,
writer: ?win32.HANDLE,
ident: [:0]u16,
info: DeviceInfo,

pub fn init(device: *HidDevice) *Kraken {
    var this = app.allocator.create(Kraken) catch unreachable;

    const ident = std.fmt.allocPrintZ(app.allocator, "X52 ({})", .{std.unicode.fmtUtf16Le(device.serial)}) catch unreachable;
    defer app.allocator.free(ident);
    this.ident = std.unicode.utf8ToUtf16LeAllocZ(app.allocator, ident) catch unreachable;
    this.device = device;
    this.reader = win32.CreateFileW(device.path, win32.GENERIC_READ, win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE, null, win32.OPEN_EXISTING, 0, null);
    this.writer = null;
    return this;
}

const FanOrPump = enum(u1) {
    FAN = 0,
    PUMP = 1,
};

pub fn control(this: *Kraken, isSave: bool, fanOrpump: FanOrPump, levels: []const u8, interval: u32) void {
    if (this.writer == null) {
        this.writer = win32.CreateFileW(this.device.path, win32.GENERIC_WRITE, win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE, null, win32.OPEN_EXISTING, 0, null);
    }

    if (this.writer == null) {
        return;
    }

    var packet: [65]u8 = undefined;

    for (0..levels.len) |i| {
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

pub fn update(this: *Kraken) callconv(.C) void {
    var packet: [65]u8 = undefined;
    var num: u32 = undefined;
    if (win32.ReadFile(this.*.reader, @ptrCast(&packet), packet.len, &num, null) != 0) {
        this.info.temp_c = @as(f64, @floatFromInt(packet[1])) + @as(f64, @floatFromInt(packet[2])) * 0.1;
        this.info.fan_rpm = @as(f64, @floatFromInt(@as(u16, packet[3]) << 8 | packet[4]));
        this.info.pump_rpm = @as(f64, @floatFromInt(@as(u16, packet[5]) << 8 | packet[6]));
    }
}

pub fn getIdent(this: *const Kraken) callconv(.C) [*:0]const u16 {
    return @ptrCast(&this.ident[0]);
}

pub fn getInfo(this: *const Kraken) callconv(.C) ?*const DeviceInfo {
    return &this.info;
}

const Curve = extern struct {
    name: [*:0]u16,
    length: u8,
    items: [1]u8,

    fn toSlice(c: *const Curve) []const u8 {
        const a: [*c]const u8 = @ptrCast(&c.items[0]);
        return a[0..c.length];
    }
};

pub fn setPumpCurve(this: *Kraken, curve: *const Curve) callconv(.C) void {
    const interval = if (curve.length == 1) 0 else @divTrunc(100, curve.length - 1);
    control(this, curve.length > 1, .PUMP, curve.toSlice(), interval);
}

pub fn setFanCurve(this: *Kraken, curve: *const Curve) callconv(.C) void {
    const interval = if (curve.length == 1) 0 else @divTrunc(100, curve.length - 1);
    control(this, curve.length > 1, .FAN, curve.toSlice(), interval);
}

pub fn deinit(this: *Kraken) callconv(.C) void {
    _ = win32.CloseHandle(this.reader);
    if (this.writer != null) {
        _ = win32.CloseHandle(this.writer.?);
    }
    this.device.deinit();
    app.allocator.free(this.ident);
    app.allocator.destroy(this);
}

pub fn getKrakens() callconv(.C) *List.ContainerType {
    var denu = DeviceEnumerator.init();
    defer denu.deinit();

    const krakens = List.create(1);

    while (denu.moveNext()) {
        if (denu.getDevice()) |hid| {
            if (hid.vendor_id == 0x1e71 and hid.product_id == 0x170e) {
                const this = init(hid);
                List.append(krakens, this);
                continue;
            }
            hid.deinit();
        }
    }

    return krakens;
}

comptime {
    @export(update, .{ .name = "Kraken_update", .linkage = .strong });
    @export(getIdent, .{ .name = "Kraken_get_ident", .linkage = .strong });
    @export(getInfo, .{ .name = "Kraken_get_info", .linkage = .strong });
    @export(setPumpCurve, .{ .name = "Kraken_set_pump_curve", .linkage = .strong });
    @export(setFanCurve, .{ .name = "Kraken_set_fan_curve", .linkage = .strong });
    @export(deinit, .{ .name = "Kraken_delete", .linkage = .strong });
    @export(getKrakens, .{ .name = "Kraken_get_krakens", .linkage = .strong });
}
