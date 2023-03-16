const std = @import("std");
const win32 = std.os.windows;

const WINAPI = win32.WINAPI;
const HINSTANCE = win32.HINSTANCE;
const HMODULE = win32.HMODULE;
const MSG = win32.user32.MSG;
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
const DWORD = win32.DWORD;
const DWORD_PTR = win32.DWORD_PTR;
const PWSTR = win32.PWSTR;
const PCWSTR = win32.PCWSTR;
const HWND = win32.HWND;
const HDC = win32.HDC;
const TRUE = win32.TRUE;
const FALSE = win32.FALSE;
const HFONT = *opaque {};
const SIZE = extern struct { cx: LONG, cy: LONG };
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
extern "user32" fn SendMessageTimeoutW(
    hWnd: HWND,
    Msg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    fuFlags: UINT,
    uTimeout: UINT,
    lpdwResult: *DWORD_PTR,
) callconv(WINAPI) LRESULT;

fn GetWindowFont(hwnd: HWND) !HFONT {
    var out: DWORD_PTR = undefined;
    const result = SendMessageTimeoutW(hwnd, win32.user32.WM_GETFONT, 0, 0, 0x0002, 100, &out);
    std.debug.print("GetWindowFont({x}) result: {x} ~ {x} ~ {x}\n", .{ @ptrToInt(hwnd), out, @intCast(usize, out), @bitCast(usize, out) });
    if (result == 0) {
        const lastError = win32.kernel32.GetLastError();
        return win32.unexpectedError(lastError);
    }
    return @intToPtr(HFONT, @bitCast(usize, out));
}

pub export fn Layout(
    hdc: HDC,
    left: i32,
    top: i32,
    nrow: u32,
    ncol: u32,
    cells: [*]*LayoutCell,
    margin: i32,
) callconv(.C) void {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    std.debug.print("Layout(hdc: {x}, {}, {}, {}, {}, cells: {x}, {})\n", .{ @ptrToInt(hdc), left, top, nrow, ncol, @ptrToInt(cells), margin });

    var rowsizes: []c_int = allocator.alloc(c_int, nrow) catch {
        std.debug.print("couldn't allocate {1} rows of {0} row sizes\n", .{ c_int, nrow });
        return;
    };
    //defer allocator.free(rowsizes);

    var baselines: []c_int = allocator.alloc(c_int, nrow) catch {
        std.debug.print("couldn't allocate {1} rows of {0} baselines\n", .{ c_int, nrow });
        return;
    };
    //defer allocator.free(baselines);

    var colsizes: []c_int = allocator.alloc(c_int, ncol) catch {
        std.debug.print("couldn't allocate {1} cols of {0} col sizes\n", .{ c_int, nrow });
        return;
    };
    //defer allocator.free(colsizes);

    var title_buffer = allocator.allocSentinel(WCHAR, 200, 0) catch {
        std.debug.print("couldn't allocate {} chars of {} for control title", .{ 200, WCHAR });
        return;
    };
    //defer allocator.free(title_buffer);

    for (0..nrow) |i| {
        rowsizes[i] = 0;
        baselines[i] = 0;

        for (0..ncol) |j| {
            var cell = cells[i * ncol + j];
            std.debug.print("processing cell {}, {}, control: {x}\n", .{ i, j, @ptrToInt(cell.control) });
            if (cell.font == null and cell.control != null) {
                std.debug.print("getting font\n", .{});
                cell.font = GetWindowFont(cell.control.?) catch null;
            }

            if (cell.font != null) {
                std.debug.print("selecting font: {x}\n", .{@ptrToInt(cell.font)});
                _ = SelectObject(hdc, @ptrCast(HGDIOBJ, cell.font.?));

                var text: ?PWSTR = cell.text;
                if (text == null and cell.control != null) {
                    std.debug.print("Getting title\n", .{});

                    _ = GetWindowTextW(cell.control.?, title_buffer, @intCast(c_int, title_buffer.len));
                    text = title_buffer;
                }
                var len = if (text != null) std.mem.len(text.?) else 0;
                std.debug.print("Title text len {}\n", .{len});
                if (len > 0) std.debug.print("Title text: '{any}'\n", .{text});

                var size: SIZE = undefined;
                var metrics: TEXTMETRICW = undefined;

                _ = GetTextExtentPoint32W(hdc, text.?, @intCast(c_int, len), &size);
                _ = GetTextMetricsW(hdc, &metrics);

                cell.width = size.cx;
                cell.height = metrics.tmHeight;
                cell.ascender = metrics.tmAscent;
            } else {
                std.debug.print("Cell has no font\n", .{});
                cell.width = 0;
                cell.height = 0;
                cell.ascender = 0;
            }

            if (cell.height > rowsizes[i]) {
                rowsizes[i] = cell.height;
            }
            if (cell.ascender > baselines[i]) {
                baselines[i] = cell.ascender;
            }
        }
    }
    std.debug.print("Measure done\n", .{});

    for (0..ncol) |j| {
        colsizes[j] = 0;

        for (0..nrow) |i| {
            var cell = cells[i * ncol + j];
            if (cell.width > colsizes[j]) {
                colsizes[j] = cell.width;
            }
        }
    }
    std.debug.print("Column maximums done\n", .{});

    var y = top;

    for (0..nrow) |i| {
        var x = left;
        var h = rowsizes[i];
        var b = baselines[i];

        for (0..ncol) |j| {
            var w = colsizes[j];
            var cell = cells[i * ncol + j];

            if (cell.control != null) {
                var r = RECT{ .left = x, .right = x + w, .top = y + b - cell.ascender, .bottom = y + h };
                std.debug.print("Moving window with r = ({}, {}, {}, {})\n", .{ r.left, r.top, r.right, r.bottom });
                if (MoveWindow(cell.control.?, r.left, r.top, r.right - r.left, r.bottom - r.top, TRUE) == FALSE) {
                    std.debug.print("MoveWindow() failed\n", .{});
                }
            }

            cell.x = x;
            cell.y = y;

            x += w + margin;
        }
        y += h + margin;
    }

    std.debug.print("Layout() done\n", .{});
}

extern var App_instance: HINSTANCE;
const Window = opaque {};
extern fn MainWindow_create() callconv(.C) *Window;
extern fn Window_show(window: *Window, show: i32) callconv(.C) void;

extern "kernel32" fn GetModuleHandleW(lpModuleName: ?PCWSTR) callconv(WINAPI) HMODULE;
extern "comctl32" fn InitCommonControls() callconv(WINAPI) void;

pub fn main() !void {
    App_instance = @ptrCast(HINSTANCE, GetModuleHandleW(null));
    InitCommonControls();

    const mw: *Window = MainWindow_create();
    Window_show(mw, 1);

    var msg: MSG = std.mem.zeroes(MSG);
    while (true) {
        win32.user32.getMessageW(&msg, null, 0, 0) catch |err| {
            if (err == error.Quit) break;
            return err;
        };
        _ = win32.user32.translateMessage(&msg);
        _ = win32.user32.dispatchMessageW(&msg);
    }
}
