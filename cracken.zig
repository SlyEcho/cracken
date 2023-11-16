const std = @import("std");
const win32 = @import("win32.zig");

const LayoutCell = extern struct {
    text: ?win32.PWSTR,
    font: ?win32.HFONT,
    height: c_int,
    width: c_int,
    ascender: c_int,
    x: c_int,
    y: c_int,
    control: ?win32.HWND,
};

pub export fn Layout(
    hdc: win32.HDC,
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

    var title_buffer = allocator.allocSentinel(win32.WCHAR, 200, 0) catch {
        std.debug.print("couldn't allocate {} chars of {} for control title", .{ 200, win32.WCHAR });
        return;
    };
    //defer allocator.free(title_buffer);

    for (0..nrow) |i| {
        rowsizes[i] = 0;
        baselines[i] = 0;

        for (0..ncol) |j| {
            var cell = cells[i * ncol + j];
            std.debug.print("processing cell {}, {}, control: {x}\n", .{ i, j, @intFromPtr(cell.control) });
            if (cell.font == null and cell.control != null) {
                std.debug.print("getting font\n", .{});
                cell.font = win32.GetWindowFont(cell.control.?) catch null;
            }

            if (cell.font != null) {
                std.debug.print("selecting font: {x}\n", .{@intFromPtr(cell.font)});
                _ = win32.SelectObject(hdc, @ptrCast(cell.font.?));

                var text: ?win32.PWSTR = cell.text;
                if (text == null and cell.control != null) {
                    std.debug.print("Getting title\n", .{});

                    _ = win32.GetWindowTextW(cell.control.?, title_buffer, @as(c_int, @intCast(title_buffer.len)));
                    text = title_buffer;
                }
                var len = if (text != null) std.mem.len(text.?) else 0;
                std.debug.print("Title text len {}\n", .{len});
                if (len > 0) std.debug.print("Title text: '{any}'\n", .{text});

                var size: win32.SIZE = undefined;
                var metrics: win32.TEXTMETRICW = undefined;

                _ = win32.GetTextExtentPoint32W(hdc, text.?, @as(c_int, @intCast(len)), &size);
                _ = win32.GetTextMetricsW(hdc, &metrics);

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
                var r = win32.RECT{ .left = x, .right = x + w, .top = y + b - cell.ascender, .bottom = y + h };
                std.debug.print("Moving window with r = ({}, {}, {}, {})\n", .{ r.left, r.top, r.right, r.bottom });
                if (win32.MoveWindow(cell.control.?, r.left, r.top, r.right - r.left, r.bottom - r.top, win32.TRUE) == win32.FALSE) {
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

extern var App_instance: win32.HINSTANCE;
const Window = opaque {};
extern fn MainWindow_create() callconv(.C) *Window;
extern fn Window_show(window: *Window, show: i32) callconv(.C) void;

pub fn main() !void {
    App_instance = @as(win32.HINSTANCE, @ptrCast(win32.GetModuleHandleW(null)));
    win32.InitCommonControls();

    const mw: *Window = MainWindow_create();
    Window_show(mw, 1);

    var msg: win32.MSG = std.mem.zeroes(win32.MSG);
    while (true) {
        win32.GetMessageW(&msg, null, 0, 0) catch |err| {
            if (err == error.Quit) break;
            return err;
        };
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageW(&msg);
    }
}
