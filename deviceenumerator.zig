const std = @import("std");
const hd = @import("hiddevice.zig");
const w = @import("win32.zig");
const Self = @This();

pub var allocator: std.mem.Allocator = undefined;

guid: w.GUID,
handle: w.HDEVINFO,
currentDeviceNr: u32,
interfaceData: w.SP_DEVICE_INTERFACE_DATA,

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
    };
}

pub fn deinit(self: *Self) void {
    _ = w.SetupDiDestroyDeviceInfoList(self.handle);
}

pub fn moveNext(self: *Self) bool {
    defer self.currentDeviceNr += 1;
    return w.SetupDiEnumDeviceInterfaces(self.handle, null, &self.guid, self.currentDeviceNr, &self.interfaceData) == w.TRUE;
}

pub fn getDevice(self: *Self) ?*hd.HidDevice {
    var detailDataSize: u32 = 0;
    _ = w.SetupDiGetDeviceInterfaceDetailW(self.handle, &self.interfaceData, null, detailDataSize, &detailDataSize, null);

    const detailDataBuf = allocator.alignedAlloc(u8, 8, detailDataSize) catch {
        return null;
    };
    defer allocator.free(detailDataBuf);

    var detailData = std.mem.bytesAsValue(w.SP_DEVICE_INTERFACE_DETAIL_DATA_W, detailDataBuf);
    detailData.cbSize = @sizeOf(w.SP_DEVICE_INTERFACE_DETAIL_DATA_W);
    if (w.SetupDiGetDeviceInterfaceDetailW(self.handle, &self.interfaceData, detailData, detailDataSize, &detailDataSize, null) == w.FALSE) {
        return null;
    }

    const path: [*c]u16 = @ptrCast(&detailData.DevicePath[0]);
    const file = w.CreateFileW(path, w.GENERIC_READ | w.GENERIC_WRITE, w.FILE_SHARE_READ | w.FILE_SHARE_WRITE, null, w.OPEN_EXISTING, 0, null);
    if (file == w.INVALID_HANDLE_VALUE) {
        return null;
    }
    defer _ = w.CloseHandle(file);
    var attributes = std.mem.zeroes(w.HIDD_ATTRIBUTES);
    attributes.Size = @sizeOf(w.HIDD_ATTRIBUTES);
    if (w.HidD_GetAttributes(file, &attributes) == 0) {
        return null;
    }
    const d = hd.HidDevice_create(attributes.VendorID, attributes.ProductID, path);
    if (w.HidD_GetSerialNumberString(file, @ptrCast(&d.serial[0]), d.serial.len) == w.FALSE) {
        d.serial[0] = 0;
    }

    return d;
}

const List = @import("list.zig");

pub export fn HidDevice_enumerate() callconv(.C) *anyopaque {
    const list = List.List_create(10);
    var de = Self.init();
    defer de.deinit();

    while (de.moveNext()) {
        if (de.getDevice()) |device| {
            List.List_append(list, device);
        }
    }

    return @ptrCast(list);
}
