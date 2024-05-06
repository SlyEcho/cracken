const std = @import("std");
const win32 = @import("win32.zig");

const LayoutCell = extern struct {
    text: ?win32.PWSTR,
    font: ?win32.HFONT,
    height: i32,
    width: i32,
    ascender: i32,
    x: i32,
    y: i32,
    control: ?win32.HWND,
};

pub fn layout(
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

    const rowsizes = allocator.alloc(i32, nrow) catch unreachable;
    const baselines = allocator.alloc(i32, nrow) catch unreachable;
    const colsizes = allocator.alloc(i32, ncol) catch unreachable;
    const title_buffer = allocator.allocSentinel(win32.WCHAR, 200, 0) catch unreachable;

    for (0..nrow) |i| {
        rowsizes[i] = 0;
        baselines[i] = 0;

        for (0..ncol) |j| {
            var cell = cells[i * ncol + j];
            //std.debug.print("processing cell {}, {}, control: {x}\n", .{ i, j, @intFromPtr(cell.control) });
            if (cell.font == null and cell.control != null) {
                //std.debug.print("getting font\n", .{});
                cell.font = win32.GetWindowFont(cell.control.?) catch null;
            }

            if (cell.font != null) {
                //std.debug.print("selecting font: {x}\n", .{@intFromPtr(cell.font)});
                _ = win32.SelectObject(hdc, @ptrCast(cell.font.?));

                var text: ?win32.PWSTR = cell.text;
                if (text == null and cell.control != null) {
                    //std.debug.print("Getting title\n", .{});

                    _ = win32.GetWindowTextW(cell.control.?, title_buffer, @intCast(title_buffer.len));
                    text = title_buffer;
                }
                const len = if (text != null) std.mem.len(text.?) else 0;
                //std.debug.print("Title text len {}\n", .{len});
                //if (len > 0) std.debug.print("Title text: '{any}'\n", .{text});

                var size: win32.SIZE = undefined;
                var metrics: win32.TEXTMETRICW = undefined;

                _ = win32.GetTextExtentPoint32W(hdc, text.?, @intCast(len), &size);
                _ = win32.GetTextMetricsW(hdc, &metrics);

                cell.width = size.cx;
                cell.height = metrics.tmHeight;
                cell.ascender = metrics.tmAscent;
            } else {
                //std.debug.print("Cell has no font\n", .{});
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
    //std.debug.print("Measure done\n", .{});

    for (0..ncol) |j| {
        colsizes[j] = 0;

        for (0..nrow) |i| {
            const cell = cells[i * ncol + j];
            if (cell.width > colsizes[j]) {
                colsizes[j] = cell.width;
            }
        }
    }
    //std.debug.print("Column maximums done\n", .{});

    var y = top;

    for (0..nrow) |i| {
        var x = left;
        const h = rowsizes[i];
        const b = baselines[i];

        for (0..ncol) |j| {
            const w = colsizes[j];
            var cell = cells[i * ncol + j];

            if (cell.control != null) {
                const r = win32.RECT{ .left = x, .right = x + w, .top = y + b - cell.ascender, .bottom = y + h };
                //std.debug.print("Moving window with r = ({}, {}, {}, {})\n", .{ r.left, r.top, r.right, r.bottom });
                if (win32.MoveWindow(cell.control.?, r.left, r.top, r.right - r.left, r.bottom - r.top, win32.TRUE) == win32.FALSE) {
                    //std.debug.print("MoveWindow() failed\n", .{});
                }
            }

            cell.x = x;
            cell.y = y;

            x += w + margin;
        }
        y += h + margin;
    }

    //std.debug.print("Layout() done\n", .{});
}

comptime {
    @export(layout, .{ .name = "Layout", .linkage = .strong });
}
