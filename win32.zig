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

pub fn GetWindowFont(hwnd: HWND) !HFONT {
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
