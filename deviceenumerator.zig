const std = @import("std");
const app = @import("app.zig");
const HidDevice = @import("hiddevice.zig");
const w = @import("win32.zig");

const Self = @This();

guid: w.GUID,
handle: w.HDEVINFO,
currentDeviceNr: u32,
interfaceData: w.SP_DEVICE_INTERFACE_DATA,
arena: std.heap.ArenaAllocator,

pub fn init() Self {
    var hidguid: w.GUID = undefined;
    w.HidD_GetHidGuid(&hidguid);

    return Self{
        .guid = hidguid,
        .handle = w.SetupDiGetClassDevsW(
            &hidguid,
            null,
            null,
            w.DIGCF_DEVICEINTERFACE | w.DIGCF_PRESENT,
        ),
        .currentDeviceNr = 0,
        .interfaceData = .{ .cbSize = @sizeOf(w.SP_DEVICE_INTERFACE_DATA), .InterfaceClassGuid = undefined, .Flags = 0, .Reserved = undefined },
        .arena = std.heap.ArenaAllocator.init(app.allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
    _ = w.SetupDiDestroyDeviceInfoList(self.handle);
}

pub fn moveNext(self: *Self) bool {
    defer self.currentDeviceNr += 1;
    return w.SetupDiEnumDeviceInterfaces(self.handle, null, &self.guid, self.currentDeviceNr, &self.interfaceData) == w.TRUE;
}

pub fn getDevice(self: *Self) ?*HidDevice {
    const allocator = self.arena.allocator();
    defer _ = self.arena.reset(.retain_capacity);

    var detailDataSize: u32 = 0;
    _ = w.SetupDiGetDeviceInterfaceDetailW(self.handle, &self.interfaceData, null, detailDataSize, &detailDataSize, null);

    const detailDataBuf = allocator.alignedAlloc(u8, .of(w.SP_DEVICE_INTERFACE_DETAIL_DATA_W), detailDataSize) catch return null;

    var detailData = @as(*w.SP_DEVICE_INTERFACE_DETAIL_DATA_W, @ptrCast(detailDataBuf.ptr));
    detailData.* = .{};
    if (w.SetupDiGetDeviceInterfaceDetailW(self.handle, &self.interfaceData, detailData, detailDataSize, &detailDataSize, null) == w.FALSE) {
        return null;
    }

    const path: [*c]u16 = @ptrCast(&detailData.DevicePath);
    const file = w.CreateFileW(path, w.GENERIC_READ | w.GENERIC_WRITE, w.FILE_SHARE_READ | w.FILE_SHARE_WRITE, null, w.OPEN_EXISTING, 0, null);
    if (file == w.INVALID_HANDLE_VALUE) {
        return null;
    }
    defer _ = w.CloseHandle(file);
    var attributes = w.HIDD_ATTRIBUTES{};
    if (w.HidD_GetAttributes(file, &attributes) == 0) {
        return null;
    }

    var serial_buf: [128:0]u16 = undefined;
    const serial: [*c]u16 = @ptrCast(&serial_buf[0]);
    if (w.HidD_GetSerialNumberString(file, serial, serial_buf.len) == w.FALSE) {
        serial_buf[0] = 0;
    }

    const d = HidDevice.init(
        attributes.VendorID,
        attributes.ProductID,
        std.mem.span(path),
        std.mem.span(serial),
    ) catch null;

    return d;
}
