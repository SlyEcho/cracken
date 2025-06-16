const builtin = @import("builtin");
const std = @import("std");
const win32 = std.os.windows;

pub const WINAPI = win32.WINAPI;
pub const HINSTANCE = win32.HINSTANCE;
pub const HMODULE = win32.HMODULE;
pub const RECT = win32.RECT;
pub const HGDIOBJ = *opaque {};
pub const LRESULT = win32.LRESULT;
pub const BOOL = win32.BOOL;
pub const UINT = win32.UINT;
pub const WPARAM = win32.WPARAM;
pub const LPARAM = win32.LPARAM;
pub const WCHAR = win32.WCHAR;
pub const BYTE = win32.BYTE;
pub const LONG = win32.LONG;
pub const DWORD = win32.DWORD;
pub const DWORD_PTR = win32.DWORD_PTR;
pub const PWSTR = win32.PWSTR;
pub const PCWSTR = win32.PCWSTR;
pub const HWND = win32.HWND;
pub const HDC = win32.HDC;
pub const TRUE = win32.TRUE;
pub const FALSE = win32.FALSE;
pub const GUID = win32.GUID;
pub const HANDLE = win32.HANDLE;
pub const INVALID_HANDLE_VALUE = @as(HANDLE, @ptrFromInt(@as(usize, @bitCast(@as(isize, -1)))));
pub const HDEVINFO = *opaque {};

pub const POINT = extern struct {
    x: LONG,
    y: LONG,
};
pub const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
    lPrivate: DWORD,
};
pub const HFONT = *opaque {};
pub const SIZE = extern struct { cx: LONG, cy: LONG };
pub const TEXTMETRICW = extern struct {
    tmHeight: LONG,
    tmAscent: LONG,
    tmDescent: LONG,
    tmInternalLeading: LONG,
    tmExternalLeading: LONG,
    tmAveCharWidth: LONG,
    tmMaxCharWidth: LONG,
    tmWeight: LONG,
    tmOverhang: LONG,
    tmDigitizedAspectX: LONG,
    tmDigitizedAspectY: LONG,
    tmFirstChar: WCHAR,
    tmLastChar: WCHAR,
    tmDefaultChar: WCHAR,
    tmBreakChar: WCHAR,
    tmItalic: BYTE,
    tmUnderlined: BYTE,
    tmStruckOut: BYTE,
    tmPitchAndFamily: BYTE,
    tmCharSet: BYTE,
};
pub const SP_DEVINFO_DATA = extern struct {
    cbSize: u32,
    ClassGuid: GUID,
    DevInst: u32,
    Reserved: *anyopaque,
};
pub const SP_DEVICE_INTERFACE_DATA = extern struct {
    cbSize: u32,
    InterfaceClassGuid: GUID,
    Flags: u32,
    Reserved: usize,
};
pub const SP_DEVICE_INTERFACE_DETAIL_DATA_W = extern struct {
    pub const SizeOf = if (builtin.cpu.arch == .x86) 6 else 8;
    cbSize: u32,
    DevicePath: u16,
};
pub const HIDD_ATTRIBUTES = extern struct {
    pub const SizeOf = 10;
    Size: u32,
    VendorID: u16,
    ProductID: u16,
    VersionNumber: u16,
};

pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?PCWSTR) callconv(WINAPI) HMODULE;
pub extern "comctl32" fn InitCommonControls() callconv(WINAPI) void;
pub extern "gdi32" fn GetTextExtentPoint32W(hdc: HDC, lpString: PWSTR, c: c_int, psize: *SIZE) callconv(WINAPI) BOOL;
pub extern "gdi32" fn GetTextMetricsW(hdc: HDC, lptm: *TEXTMETRICW) callconv(WINAPI) BOOL;
pub extern "gdi32" fn SelectObject(hdc: HDC, h: HGDIOBJ) callconv(WINAPI) HGDIOBJ;
pub extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: PWSTR, nMaxCount: c_int) callconv(WINAPI) c_int;
pub extern "user32" fn GetWindowTextLengthW(hWnd: HWND) callconv(WINAPI) c_int;
pub extern "user32" fn MoveWindow(hWnd: HWND, X: c_int, Y: c_int, nWidth: c_int, nHeight: c_int, bRepaint: BOOL) callconv(WINAPI) BOOL;
pub extern "user32" fn SendMessageTimeoutW(
    hWnd: HWND,
    Msg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    fuFlags: UINT,
    uTimeout: UINT,
    lpdwResult: *DWORD_PTR,
) callconv(WINAPI) LRESULT;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(WINAPI) BOOL;
pub extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(WINAPI) BOOL;
pub extern "user32" fn SetWindowPos(
    hWnd: HWND,
    hWndInsertAfter: ?HWND,
    x: i32,
    y: i32,
    cx: i32,
    cy: i32,
    uFlags: u32,
) callconv(WINAPI) BOOL;

pub fn getWindowFont(hwnd: HWND) !HFONT {
    var out: DWORD_PTR = undefined;
    const WM_GETFONT = 0x0031;
    const result = SendMessageTimeoutW(hwnd, WM_GETFONT, 0, 0, 0x0002, 100, &out);

    if (result == 0) {
        const lastError = win32.kernel32.GetLastError();
        return win32.unexpectedError(lastError);
    }
    return @as(HFONT, @ptrFromInt(@as(usize, @bitCast(out))));
}

pub extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(WINAPI) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(WINAPI) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(WINAPI) LRESULT;

pub const GENERIC_READ = 0x80000000;
pub const GENERIC_WRITE = 0x40000000;
pub const GENERIC_EXECUTE = 0x20000000;
pub const GENERIC_ALL = 0x10000000;
pub const FILE_SHARE_READ = 0x00000001;
pub const FILE_SHARE_WRITE = 0x00000002;
pub const FILE_SHARE_DELETE = 0x00000004;
pub const CREATE_NEW = 1;
pub const CREATE_ALWAYS = 2;
pub const OPEN_EXISTING = 3;
pub const OPEN_ALWAYS = 4;
pub const TRUNCATE_EXISTING = 5;
pub const DIGCF_DEFAULT = 0x00000001; // only valid with DIGCF_DEVICEINTERFACE
pub const DIGCF_PRESENT = 0x00000002;
pub const DIGCF_ALLCLASSES = 0x00000004;
pub const DIGCF_PROFILE = 0x00000008;
pub const DIGCF_DEVICEINTERFACE = 0x00000010;
pub const DIGCF_INTERFACEDEVICE = DIGCF_DEVICEINTERFACE;
pub const SW_SHOWDEFAULT = 10;
pub const SWP_NOZORDER = 0x0004;
pub const SWP_NOACTIVATE = 0x0010;

pub const CreateFileW = win32.kernel32.CreateFileW;
pub const ReadFile = win32.kernel32.ReadFile;
pub const WriteFile = win32.kernel32.WriteFile;
pub const CloseHandle = win32.CloseHandle;

pub extern "setupapi" fn HidD_GetHidGuid(HidGuid: *GUID) callconv(WINAPI) void;
pub extern "setupapi" fn SetupDiGetClassDevsW(
    ClassGuid: *const GUID,
    Enumerator: [*c]const u16,
    hwndParent: ?HWND,
    Flags: u32,
) callconv(WINAPI) HDEVINFO;
pub extern "setupapi" fn SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO) callconv(WINAPI) BOOL;
pub extern "setupapi" fn SetupDiEnumDeviceInterfaces(
    DeviceInfoSet: HDEVINFO,
    DeviceInfoData: ?*SP_DEVINFO_DATA,
    InterfaceClassGuid: *const GUID,
    MemberIndex: u32,
    DeviceInterfaceDat: *SP_DEVICE_INTERFACE_DATA,
) callconv(WINAPI) BOOL;
pub extern "setupapi" fn SetupDiGetDeviceInterfaceDetailW(
    DeviceInfoSet: HDEVINFO,
    DeviceInterfaceData: *SP_DEVICE_INTERFACE_DATA,
    DeviceInterfaceDetailData: ?*SP_DEVICE_INTERFACE_DETAIL_DATA_W,
    DeviceInterfaceDetailDataSize: u32,
    RequiredSize: *u32,
    DeviceInfoData: ?*SP_DEVINFO_DATA,
) callconv(WINAPI) BOOL;

pub extern "hid" fn HidD_GetAttributes(
    HidDeviceObject: HANDLE,
    Attributes: *HIDD_ATTRIBUTES,
) callconv(WINAPI) BOOL;
pub extern "hid" fn HidD_GetSerialNumberString(
    HidDeviceObject: HANDLE,
    Buffer: [*:0]u16,
    BufferLength: u32,
) callconv(WINAPI) BOOL;

pub const SB_HORZ = 0;
pub const SB_VERT = 1;
pub const SB_CTL = 2;
pub const SB_BOTH = 3;

pub const SIF_RANGE = 0x0001;
pub const SIF_PAGE = 0x0002;
pub const SIF_POS = 0x0004;
pub const SIF_DISABLENOSCROLL = 0x0008;
pub const SIF_TRACKPOS = 0x0010;
pub const SIF_ALL = (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS);

pub const SCROLLINFO = struct {
    cbSize: UINT = @sizeOf(SCROLLINFO),
    fMask: UINT = 0,
    nMin: i32 = 0,
    nMax: i32 = 0,
    nPage: UINT = 0,
    nPos: i32 = 0,
    nTrackPos: i32 = 0,
};

pub extern "user32" fn GetScrollInfo(hwnd: HWND, nBar: i32, lpsi: *SCROLLINFO) callconv(WINAPI) BOOL;
pub extern "user32" fn SetScrollInfo(hwnd: HWND, nBar: i32, lpsi: *const SCROLLINFO, redraw: BOOL) callconv(WINAPI) i32;
pub extern "user32" fn ScrollWindow(
    hWnd: HWND,
    XAmount: i32,
    YAmount: i32,
    lpRect: ?*const RECT,
    lpClipRect: ?*const RECT,
) callconv(WINAPI) BOOL;
