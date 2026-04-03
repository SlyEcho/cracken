const builtin = @import("builtin");
const std = @import("std");
const win32 = std.os.windows;

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
pub const HBRUSH = *opaque {};
pub const HMENU = *opaque {};
pub const HICON = *opaque {};
pub const HCURSOR = *opaque {};
pub const ATOM = win32.WORD;
pub const LONG_PTR = win32.LONG_PTR;

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

pub const WNDPROC = *const fn (hwnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;

pub const WNDCLASSW = extern struct {
    style: UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: c_int = 0,
    cbWndExtra: c_int = 0,
    hInstance: HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?PCWSTR,
    lpszClassName: PCWSTR,
};

pub const CREATESTRUCTW = extern struct {
    lpCreateParams: ?*anyopaque,
    hInstance: HINSTANCE,
    hMenu: ?HMENU,
    hwndParent: ?HWND,
    cy: c_int,
    cx: c_int,
    y: c_int,
    x: c_int,
    style: LONG,
    lpszName: ?PCWSTR,
    lpszClass: ?PCWSTR,
    dwExStyle: DWORD,
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
    cbSize: u32 = if (builtin.cpu.arch == .x86) 6 else 8,
    DevicePath: u16 = 0,
};
pub const HIDD_ATTRIBUTES = extern struct {
    cbSize: u32 = 12,
    VendorID: u16 = 0,
    ProductID: u16 = 0,
    VersionNumber: u16 = 0,
};

pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?PCWSTR) callconv(.winapi) HMODULE;
pub extern "comctl32" fn InitCommonControls() callconv(.winapi) void;
pub extern "gdi32" fn GetTextExtentPoint32W(hdc: HDC, lpString: PWSTR, c: c_int, psize: *SIZE) callconv(.winapi) BOOL;
pub extern "gdi32" fn GetTextMetricsW(hdc: HDC, lptm: *TEXTMETRICW) callconv(.winapi) BOOL;
pub extern "gdi32" fn SelectObject(hdc: HDC, h: HGDIOBJ) callconv(.winapi) HGDIOBJ;
pub extern "gdi32" fn SetBkMode(hdc: HDC, mode: c_int) callconv(.winapi) c_int;
pub extern "gdi32" fn SetTextColor(hdc: HDC, color: u32) callconv(.winapi) u32;
pub extern "gdi32" fn DeleteObject(ho: HGDIOBJ) callconv(.winapi) BOOL;
pub extern "gdi32" fn CreateFontW(
    cHeight: c_int,
    cWidth: c_int,
    cEscapement: c_int,
    cOrientation: c_int,
    cWeight: c_int,
    bItalic: DWORD,
    bUnderline: DWORD,
    bStrikeOut: DWORD,
    iCharSet: DWORD,
    iOutPrecision: DWORD,
    iClipPrecision: DWORD,
    iQuality: DWORD,
    iPitchAndFamily: DWORD,
    pszFaceName: ?PCWSTR,
) callconv(.winapi) HFONT;
pub extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: PWSTR, nMaxCount: c_int) callconv(.winapi) c_int;
pub extern "user32" fn GetWindowTextLengthW(hWnd: HWND) callconv(.winapi) c_int;
pub extern "user32" fn MoveWindow(hWnd: HWND, X: c_int, Y: c_int, nWidth: c_int, nHeight: c_int, bRepaint: BOOL) callconv(.winapi) BOOL;
pub extern "user32" fn GetDC(hWnd: ?HWND) callconv(.winapi) ?HDC;
pub extern "user32" fn ReleaseDC(hWnd: ?HWND, hDC: ?HDC) callconv(.winapi) c_int;
pub extern "user32" fn SetWindowTextW(hWnd: HWND, lpString: ?PCWSTR) callconv(.winapi) BOOL;
pub extern "user32" fn SendMessageTimeoutW(
    hWnd: HWND,
    Msg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    fuFlags: UINT,
    uTimeout: UINT,
    lpdwResult: *DWORD_PTR,
) callconv(.winapi) LRESULT;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(.winapi) BOOL;
pub extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowPos(
    hWnd: HWND,
    hWndInsertAfter: ?HWND,
    x: i32,
    y: i32,
    cx: i32,
    cy: i32,
    uFlags: u32,
) callconv(.winapi) BOOL;

pub extern "user32" fn GetDpiForWindow(hwnd: HWND) callconv(.winapi) UINT;
pub extern "user32" fn GetDpiForSystem() callconv(.winapi) UINT;
pub extern "user32" fn SystemParametersInfoW(uiAction: UINT, uiParam: UINT, pvParam: ?*anyopaque, fWinIni: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn SetWindowLongW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) callconv(.winapi) LONG;
pub extern "user32" fn GetWindowLongW(hWnd: HWND, nIndex: c_int) callconv(.winapi) LONG;
pub extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) callconv(.winapi) LONG_PTR;
pub extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: c_int) callconv(.winapi) LONG_PTR;
pub extern "user32" fn LoadCursorW(hInstance: ?HINSTANCE, lpCursorName: ?PCWSTR) callconv(.winapi) HCURSOR;
pub extern "user32" fn SetCursor(hCursor: ?HCURSOR) callconv(.winapi) ?HCURSOR;
pub extern "user32" fn RegisterClassW(lpWndClass: *const WNDCLASSW) callconv(.winapi) ATOM;
pub extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: PCWSTR,
    lpWindowName: ?PCWSTR,
    dwStyle: DWORD,
    X: c_int,
    Y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: ?HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(.winapi) HWND;
pub extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;

pub fn setWindowLongPtr(hwnd: HWND, nIndex: c_int, value: LONG_PTR) LONG_PTR {
    if (@sizeOf(usize) == 4) {
        return @as(LONG_PTR, @intCast(SetWindowLongW(hwnd, nIndex, @as(LONG, @intCast(value)))));
    }
    return SetWindowLongPtrW(hwnd, nIndex, value);
}

pub fn getWindowLongPtr(hwnd: HWND, nIndex: c_int) LONG_PTR {
    if (@sizeOf(usize) == 4) {
        return @as(LONG_PTR, @intCast(GetWindowLongW(hwnd, nIndex)));
    }
    return GetWindowLongPtrW(hwnd, nIndex);
}

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

pub extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
pub extern "user32" fn PostQuitMessage(nExitCode: c_int) callconv(.winapi) void;
pub extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.winapi) BOOL;
pub extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn GetSysColorBrush(nIndex: c_int) callconv(.winapi) HBRUSH;
pub extern "user32" fn SetTimer(hWnd: ?HWND, nIDEvent: usize, uElapse: UINT, lpTimerFunc: ?*const anyopaque) callconv(.winapi) usize;

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

pub const WM_CREATE = 0x0001;
pub const WM_DESTROY = 0x0002;
pub const WM_SETFONT = 0x0030;
pub const WM_SIZE = 0x0005;
pub const WM_PAINT = 0x000F;
pub const WM_COMMAND = 0x0111;
pub const WM_TIMER = 0x0113;
pub const WM_VSCROLL = 0x0115;
pub const WM_MOUSEWHEEL = 0x020A;
pub const WM_DPICHANGED = 0x02E0;
pub const WM_DPICHANGED_BEFOREPARENT = 0x02E2;
pub const WM_CTLCOLORSTATIC = 0x0138;

pub const WS_OVERLAPPED = 0x00000000;
pub const WS_CHILD = 0x40000000;
pub const WS_VISIBLE = 0x10000000;
pub const WS_OVERLAPPEDWINDOW = 0x00CF0000;
pub const WS_VSCROLL = 0x00200000;

pub const SPI_GETWHEELSCROLLLINES = 0x0068;
pub const WHEEL_DELTA = 120;

pub const SB_LINEUP = 0;
pub const SB_LINEDOWN = 1;
pub const SB_PAGEUP = 2;
pub const SB_PAGEDOWN = 3;
pub const SB_THUMBTRACK = 5;
pub const SB_TOP = 6;
pub const SB_BOTTOM = 7;

pub const BN_CLICKED = 0;
pub const CBN_SELCHANGE = 1;
pub const CB_ADDSTRING = 0x0143;
pub const CB_GETCURSEL = 0x0147;
pub const CB_ERR: i32 = -1;

pub const GWLP_USERDATA = -21;

pub const CS_VREDRAW = 0x0001;
pub const CS_HREDRAW = 0x0002;

pub const CW_USEDEFAULT = @as(c_int, @bitCast(@as(c_uint, 0x80000000)));

pub const COLOR_WINDOW = 5;
pub const DEFAULT_CHARSET = 1;
pub const FW_BOLD = 700;
pub const CBS_DROPDOWNLIST = 0x0003;
pub const CBS_HASSTRINGS = 0x0200;
pub const SS_LEFT = 0x00000000;
pub const SS_CENTER = 0x00000001;
pub const SS_RIGHT = 0x00000002;
pub const SS_CENTERIMAGE = 0x00000200;
pub const TRANSPARENT = 1;

pub const IDC_ARROW: [*:0]const u16 = @ptrFromInt(32512);
pub const IDC_APPSTARTING: [*:0]const u16 = @ptrFromInt(32650);

pub const CreateFileW = win32.kernel32.CreateFileW;
pub const ReadFile = win32.kernel32.ReadFile;
pub const WriteFile = win32.kernel32.WriteFile;
pub const CloseHandle = win32.CloseHandle;

pub extern "setupapi" fn HidD_GetHidGuid(HidGuid: *GUID) callconv(.winapi) void;
pub extern "setupapi" fn SetupDiGetClassDevsW(
    ClassGuid: *const GUID,
    Enumerator: [*c]const u16,
    hwndParent: ?HWND,
    Flags: u32,
) callconv(.winapi) HDEVINFO;
pub extern "setupapi" fn SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO) callconv(.winapi) BOOL;
pub extern "setupapi" fn SetupDiEnumDeviceInterfaces(
    DeviceInfoSet: HDEVINFO,
    DeviceInfoData: ?*SP_DEVINFO_DATA,
    InterfaceClassGuid: *const GUID,
    MemberIndex: u32,
    DeviceInterfaceDat: *SP_DEVICE_INTERFACE_DATA,
) callconv(.winapi) BOOL;
pub extern "setupapi" fn SetupDiGetDeviceInterfaceDetailW(
    DeviceInfoSet: HDEVINFO,
    DeviceInterfaceData: *SP_DEVICE_INTERFACE_DATA,
    DeviceInterfaceDetailData: ?*SP_DEVICE_INTERFACE_DETAIL_DATA_W,
    DeviceInterfaceDetailDataSize: u32,
    RequiredSize: *u32,
    DeviceInfoData: ?*SP_DEVINFO_DATA,
) callconv(.winapi) BOOL;

pub extern "hid" fn HidD_GetAttributes(
    HidDeviceObject: HANDLE,
    Attributes: *HIDD_ATTRIBUTES,
) callconv(.winapi) BOOL;
pub extern "hid" fn HidD_GetSerialNumberString(
    HidDeviceObject: HANDLE,
    Buffer: [*:0]u16,
    BufferLength: u32,
) callconv(.winapi) BOOL;

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

pub const SCROLLINFO = extern struct {
    cbSize: UINT = @sizeOf(SCROLLINFO),
    fMask: UINT = 0,
    nMin: i32 = 0,
    nMax: i32 = 0,
    nPage: UINT = 0,
    nPos: i32 = 0,
    nTrackPos: i32 = 0,
};

pub extern "user32" fn GetScrollInfo(hwnd: HWND, nBar: i32, lpsi: *SCROLLINFO) callconv(.winapi) BOOL;
pub extern "user32" fn SetScrollInfo(hwnd: HWND, nBar: i32, lpsi: *const SCROLLINFO, redraw: BOOL) callconv(.winapi) i32;
pub extern "user32" fn ScrollWindow(
    hWnd: HWND,
    XAmount: i32,
    YAmount: i32,
    lpRect: ?*const RECT,
    lpClipRect: ?*const RECT,
) callconv(.winapi) BOOL;

pub const FontOptions = struct {
    width: i32 = 0,
    escapement: i32 = 0,
    orientation: i32 = 0,
    weight: i32 = 0,
    italic: bool = false,
    underline: bool = false,
    strike_out: bool = false,
    char_set: DWORD = DEFAULT_CHARSET,
    out_precision: DWORD = 0,
    clip_precision: DWORD = 0,
    quality: DWORD = 0,
    pitch_and_family: DWORD = 0,
};

pub fn createFont(height: i32, face_name: ?PCWSTR, options: FontOptions) HFONT {
    return CreateFontW(
        height,
        options.width,
        options.escapement,
        options.orientation,
        options.weight,
        @intFromBool(options.italic),
        @intFromBool(options.underline),
        @intFromBool(options.strike_out),
        options.char_set,
        options.out_precision,
        options.clip_precision,
        options.quality,
        options.pitch_and_family,
        face_name,
    );
}

pub const CreateWindowOptions = struct {
    ex_style: DWORD = 0,
    style: DWORD,
    x: c_int = CW_USEDEFAULT,
    y: c_int = CW_USEDEFAULT,
    width: c_int = 0,
    height: c_int = 0,
    parent: ?HWND = null,
    menu: ?HMENU = null,
    instance: ?HINSTANCE = null,
    param: ?*anyopaque = null,
};

pub fn createWindow(class_name: PCWSTR, title: ?PCWSTR, options: CreateWindowOptions) HWND {
    return CreateWindowExW(
        options.ex_style,
        class_name,
        title,
        options.style,
        options.x,
        options.y,
        options.width,
        options.height,
        options.parent,
        options.menu,
        options.instance,
        options.param,
    );
}

pub fn LOWORD(l: anytype) u16 {
    return @truncate(@as(usize, @bitCast(l)) & 0xffff);
}

pub fn HIWORD(l: anytype) u16 {
    return @truncate((@as(usize, @bitCast(l)) >> 16) & 0xffff);
}

pub fn GET_WHEEL_DELTA_WPARAM(wParam: WPARAM) i16 {
    return @bitCast(@as(u16, @truncate((wParam >> 16) & 0xffff)));
}

pub fn MAKELONG(a: u16, b: u16) u32 {
    return @as(u32, a) | (@as(u32, b) << 16);
}

pub fn RGB(r: u8, g: u8, b: u8) u32 {
    return @as(u32, r) | (@as(u32, g) << 8) | (@as(u32, b) << 16);
}
