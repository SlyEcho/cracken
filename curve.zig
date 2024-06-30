const std = @import("std");

pub const Curve = extern struct {
    name: [16:0]u16,
    length: u8,
    items: [31]u8,

    fn fromSlice(comptime name: [:0]const u8, items: []const u8) Curve {
        var c: Curve = undefined;
        const u16name = std.unicode.utf8ToUtf16LeStringLiteral(name);
        @memcpy(c.name[0..u16name.len], u16name);
        c.length = items.len;
        @memcpy(c.items[0..c.length], items);
        return c;
    }

    fn fromFixed(pct: u8) Curve {
        var c: Curve = undefined;
        const u8name = std.fmt.comptimePrint("Fixed {d}%", .{pct});
        const name = std.unicode.utf8ToUtf16LeStringLiteral(u8name);
        @memcpy(c.name[0..name.len], name);
        c.length = 1;
        c.items[0] = pct;
        return c;
    }

    pub fn toSlice(c: *const Curve) []const u8 {
        return c.items[0..c.length];
    }
};

const presets = struct {
    const fan: [6:null]?*const Curve = .{
        &Curve.fromSlice("Silent", &.{ 25, 25, 25, 25, 25, 25, 25, 25, 35, 45, 55, 75, 100, 100, 100, 100, 100, 100, 100, 100, 100 }),
        &Curve.fromSlice("Performance", &.{ 50, 50, 50, 50, 50, 50, 50, 50, 60, 70, 80, 90, 100, 100, 100, 100, 100, 100, 100, 100, 100 }),
        &Curve.fromFixed(25),
        &Curve.fromFixed(50),
        &Curve.fromFixed(75),
        &Curve.fromFixed(100),
    };

    const pump: [6:null]?*const Curve = .{
        &Curve.fromSlice("Silent", &.{ 60, 60, 60, 60, 60, 60, 60, 60, 70, 80, 90, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100 }),
        &Curve.fromSlice("Performance", &.{ 70, 70, 70, 70, 70, 70, 70, 70, 80, 85, 90, 95, 100, 100, 100, 100, 100, 100, 100, 100, 100 }),
        &Curve.fromFixed(25),
        &Curve.fromFixed(50),
        &Curve.fromFixed(75),
        &Curve.fromFixed(100),
    };
};

comptime {
    @export(presets.fan, .{ .name = "Curve_fan_presets", .linkage = .strong });
    @export(presets.pump, .{ .name = "Curve_pump_presets", .linkage = .strong });
}
