const std = @import("std");
const win32 = std.os.windows;

const WINAPI = win32.WINAPI;
const RECT = win32.RECT;
const HGDIOBJ = *opaque {};
const LRESULT = win32.LRESULT;
const BOOL = win32.BOOL;
const UINT = win32.UINT;
const WPARAM = win32.WPARAM;
const LPARAM = win32.LPARAM;
const WCHAR = win32.WCHAR;
const BYTE = win32.BYTE;
const LONG = win32.LONG;
const PWSTR = win32.PWSTR;
const HWND = win32.HWND;
const HDC = win32.HDC;
const TRUE = win32.TRUE;
const HFONT = *opaque {};
const SIZE = extern struct {
    cx: LONG,
    cy: LONG,
};
const TEXTMETRICW = extern struct {
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
const LayoutCell = extern struct {
    text: ?PWSTR,
    font: ?HFONT,
    height: c_int,
    width: c_int,
    ascender: c_int,
    x: c_int,
    y: c_int,
    control: ?HWND,
};

extern "gdi32" fn GetTextExtentPoint32W(hdc: HDC, lpString: PWSTR, c: c_int, psize: *SIZE) callconv(WINAPI) BOOL;
extern "gdi32" fn GetTextMetricsW(hdc: HDC, lptm: *TEXTMETRICW) callconv(WINAPI) BOOL;
extern "gdi32" fn SelectObject(hdc: HDC, h: HGDIOBJ) callconv(WINAPI) HGDIOBJ;
extern "user32" fn GetWindowTextW(hWnd: HWND, lpString: PWSTR, nMaxCount: c_int) callconv(WINAPI) c_int;
extern "user32" fn GetWindowTextLengthW(hWnd: HWND) callconv(WINAPI) c_int;
extern "user32" fn MoveWindow(hWnd: HWND, X: c_int, Y: c_int, nWidth: c_int, nHeight: c_int, bRepaint: BOOL) callconv(WINAPI) BOOL;
extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;

fn GetWindowFont(hwnd: HWND) ?HFONT {
    return @intToPtr(HFONT, @intCast(usize, SendMessageW(hwnd, win32.user32.WM_GETFONT, 0, 0)));
}

var buffer: [4096]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

pub export fn Layout(hdc: HDC, left: c_int, top: c_int, c_nrow: c_int, c_ncol: c_int, cells: [*]*LayoutCell, margin: c_int) callconv(.C) void {

    const nrow = @intCast(usize, c_nrow);
    const ncol = @intCast(usize, c_ncol);

    var rowsizes: []c_int = allocator.alloc(c_int, nrow) catch return;
    defer allocator.free(rowsizes);

    var baselines: []c_int = allocator.alloc(c_int, nrow) catch return;
    defer allocator.free(baselines);

    var colsizes: []c_int = allocator.alloc(c_int, ncol) catch return;
    defer allocator.free(colsizes);

    var i: usize = 0;
    var j: usize = 0;

    i = 0;
    while (i < nrow) : (i += 1) {
        rowsizes[i] = 0;
        baselines[i] = 0;

        j = 0;
        while (j < ncol) : (j += 1) {
            var cell = cells[i * ncol + j];
            if (cell.font == null and cell.control != null) {
                cell.font = GetWindowFont(cell.control.?);
            }
            _ = SelectObject(hdc, @ptrCast(HGDIOBJ, cell.font));
            var text: ?PWSTR = cell.text;
            if (text == null and cell.control != null) {
                var len = GetWindowTextLengthW(cell.control.?);
                var title_buffer = allocator.allocSentinel(WCHAR, @intCast(usize, len), 0) catch return;
                defer allocator.free(title_buffer);
                _ = GetWindowTextW(cell.control.?, title_buffer, len);
                text = title_buffer;
            }
            var len = if (text != null) std.mem.len(text.?) else 0;
            
            var size: SIZE = undefined;
            _ = GetTextExtentPoint32W(hdc, text.?, @intCast(c_int, len), &size);
            
            var metrics: TEXTMETRICW = undefined;
            _ = GetTextMetricsW(hdc, &metrics);
            cell.width = size.cx;
            cell.height = metrics.tmHeight;
            cell.ascender = metrics.tmAscent;
            if (cell.height > rowsizes[i]) {
                rowsizes[i] = cell.height;
            }
            if (cell.ascender > baselines[i]) {
                baselines[i] = cell.ascender;
            }
        }
    }

    j = 0;
    while (j < ncol) : (j += 1) {
        colsizes[j] = 0;
        i = 0;
        while (i < nrow) : (i += 1) {
            var cell = cells[i * ncol + j];
            if (cell.width > colsizes[j]) {
                colsizes[j] = cell.width;
            }
        }
    }

    var y = top;
    while (i < nrow) : (i += 1) {
        var x = left;
        var h = rowsizes[i];
        var b = baselines[i];
        while (j < ncol) : (j += 1) {
            var w = colsizes[j];
            var cell = cells[i * ncol + j];

            var r = RECT{ .left = x, .right = x + w, .top = y + b - cell.ascender, .bottom = y + h };
            _ = MoveWindow(cell.control.?, r.left, r.top, r.right - r.left, r.bottom - r.top, TRUE);

            cell.x = x;
            cell.y = y;

            x += w + margin;
        }
        y += h + margin;
    }
}
