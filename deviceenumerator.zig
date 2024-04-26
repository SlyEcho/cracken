const std = @import("std");
const hd = @import("hiddevice.zig");
const Self = @This();
const WINAPI = std.os.windows.WINAPI;
const BOOL = std.os.windows.BOOL;
const HWND = std.os.windows.HWND;
const GUID = std.os.windows.GUID;
const HANDLE = std.os.windows.HANDLE;

const HDEVINFO = *opaque {};
const SP_DEVINFO_DATA = extern struct {
    cbSize: u32,
    ClassGuid: GUID,
    DevInst: u32,
    Reserved: *anyopaque,
};
const SP_DEVICE_INTERFACE_DATA = extern struct {
    cbSize: u32,
    InterfaceClassGuid: GUID,
    Flags: u32,
    Reserved: *anyopaque,
};
const SP_DEVICE_INTERFACE_DETAIL_DATA_W = extern struct {
    cbSize: u32,
    DevicePath: [1]u16,
};
const HIDD_ATTRIBUTES = extern struct {
    Size: u32,
    VendorID: u16,
    ProductID: u16,
    VersionNumber: u16,
};

const GENERIC_READ = 0x80000000;
const GENERIC_WRITE = 0x40000000;
const GENERIC_EXECUTE = 0x20000000;
const GENERIC_ALL = 0x10000000;
const FILE_SHARE_READ = 0x00000001;
const FILE_SHARE_WRITE = 0x00000002;
const FILE_SHARE_DELETE = 0x00000004;
const CREATE_NEW = 1;
const CREATE_ALWAYS = 2;
const OPEN_EXISTING = 3;
const OPEN_ALWAYS = 4;
const TRUNCATE_EXISTING = 5;
const DIGCF_DEFAULT = 0x00000001; // only valid with DIGCF_DEVICEINTERFACE
const DIGCF_PRESENT = 0x00000002;
const DIGCF_ALLCLASSES = 0x00000004;
const DIGCF_PROFILE = 0x00000008;
const DIGCF_DEVICEINTERFACE = 0x00000010;
const DIGCF_INTERFACEDEVICE = DIGCF_DEVICEINTERFACE;

const CreateFileW = std.os.windows.kernel32.CreateFileW;
const CloseHandle = std.os.windows.kernel32.CloseHandle;

extern "setupapi" fn HidD_GetHidGuid(HidGuid: *GUID) callconv(WINAPI) void;
extern "setupapi" fn SetupDiGetClassDevsW(
    ClassGuid: *const GUID,
    Enumerator: [*c]const u16,
    hwndParent: HWND,
    Flags: u32,
) callconv(WINAPI) HDEVINFO;
extern "setupapi" fn SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO) callconv(WINAPI) BOOL;
extern "setupapi" fn SetupDiEnumDeviceInterfaces(
    DeviceInfoSet: HDEVINFO,
    DeviceInfoData: ?*SP_DEVINFO_DATA,
    InterfaceClassGuid: *const GUID,
    MemberIndex: u32,
    DeviceInterfaceDat: *SP_DEVICE_INTERFACE_DATA,
) callconv(WINAPI) BOOL;
extern "setupapi" fn SetupDiGetDeviceInterfaceDetailW(
    DeviceInfoSet: HDEVINFO,
    DeviceInterfaceData: *SP_DEVICE_INTERFACE_DATA,
    DeviceInterfaceDetailData: ?*SP_DEVICE_INTERFACE_DETAIL_DATA_W,
    DeviceInterfaceDetailDataSize: u32,
    RequiredSize: *u32,
    DeviceInfoData: ?*SP_DEVINFO_DATA,
) callconv(WINAPI) BOOL;
extern "hid" fn HidD_GetAttributes(
    HidDeviceObject: HANDLE,
    Attributes: *HIDD_ATTRIBUTES,
) callconv(WINAPI) BOOL;
extern "hid" fn HidD_GetSerialNumberString(
    HidDeviceObject: HANDLE,
    Buffer: [*:0]u16,
    BufferLength: u32,
) callconv(WINAPI) BOOL;

var allocator: std.mem.Allocator = undefined;

guid: GUID,
handle: HDEVINFO,
currentDeviceNr: usize,
interfaceData: SP_DEVICE_INTERFACE_DATA,

pub fn init() Self {
    var hidguid: GUID = undefined;
    HidD_GetHidGuid(&hidguid);

    return Self{
        .guid = hidguid,
        .handle = SetupDiGetClassDevsW(
            &hidguid,
            null,
            null,
            DIGCF_DEVICEINTERFACE | DIGCF_PRESENT,
        ),
        .currentDeviceNr = 0,
        .interfaceData = .{
            .cbSize = @sizeOf(SP_DEVICE_INTERFACE_DATA),
        },
    };
}

pub fn deinit(self: *Self) void {
    SetupDiDestroyDeviceInfoList(self.handle);
}

pub fn moveNext(self: *Self) bool {
    self.currentDeviceNr += 1;
    return SetupDiEnumDeviceInterfaces(
        self.handle,
        null,
        &self.guid,
        self.currentDeviceNr,
        &self.interfaceData,
    );
}

pub fn getDevice(self: *Self) ?*hd.HidDevice {
    var detailDataSize: u32 = 0;
    SetupDiGetDeviceInterfaceDetailW(
        self.handle,
        self.interfaceData,
        null,
        detailDataSize,
        &detailDataSize,
        null,
    );

    const detailDataBuf = allocator.alloc(u8, detailDataSize) catch {
        return null;
    };
    defer allocator.free(detailDataBuf);

    const detailData = std.mem.bytesAsValue(SP_DEVICE_INTERFACE_DETAIL_DATA_W, detailDataBuf);
    detailData.cbSize = @sizeOf(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
    if (SetupDiGetDeviceInterfaceDetailW(
        self.handle,
        self.interfaceData,
        &detailData,
        detailDataSize,
        &detailDataSize,
        null,
    ) == 0) {
        return null;
    }

    const file = CreateFileW(
        detailData.DevicePath,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        null,
        OPEN_EXISTING,
        0,
        null,
    );
    if (file == null) {
        return null;
    }
    defer CloseHandle(file);
    const attributes = HIDD_ATTRIBUTES{ .Size = @sizeOf(HIDD_ATTRIBUTES) };
    if (HidD_GetAttributes(file, &attributes) == 0) {
        return null;
    }
    const d = hd.HidDevice_create(attributes.VendorID, attributes.ProductID, detailData.DevicePath);
    if (HidD_GetSerialNumberString(file, d.serial, @sizeOf(d.serial))) {
        d.serial[0] = 0;
    }

    return d;
}
