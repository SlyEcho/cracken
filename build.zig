const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const tgt = b.standardTargetOptions(.{
        .default_target = try std.zig.CrossTarget.parse(.{
            .arch_os_abi = "x86_64-windows-gnu"
        })
    });
    const exe = b.addExecutable("cracken", null);
    exe.setBuildMode(mode);
    exe.setTarget(tgt);
    exe.subsystem = .Windows;
    exe.c_std = .C11;

    if (mode != .Debug) {
        exe.strip = true;
    }
    
    const flags = [_][] const u8 { "-DUNICODE" };
    const sources = [_][] const u8 {
        "app.c",
        "curve.c",
        "deviceenumerator.c",
        "hiddevice.c",
        "kraken.c",
        "krakenwidget.c",
        "layout.c",
        "list.c",
        "main.c",
        "mainwindow.c",
        "window.c",
        "xalloc.c"
    };

    exe.addCSourceFiles(&sources, &flags);
    
    exe.linkLibC();
    exe.linkSystemLibrary("setupapi");
    exe.linkSystemLibrary("hid");
    exe.linkSystemLibrary("comctl32");
    exe.linkSystemLibrary("gdi32");

    exe.install();
}
