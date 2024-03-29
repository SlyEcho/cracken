const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardOptimizeOption(.{});
    const tgt = b.standardTargetOptions(.{
        .default_target = try std.zig.CrossTarget.parse(.{
            .arch_os_abi = "x86_64-windows-gnu",
        }),
    });
    const exe = b.addExecutable(.{
        .name = "cracken",
        .root_source_file = .{ .path = "cracken.zig" },
        .target = tgt,
        .optimize = mode,
    });
    exe.c_std = .C11;
    exe.want_lto = true;

    if (mode != .Debug) {
        exe.subsystem = .Windows;
        exe.strip = true;
    }

    const flags = .{ "-DUNICODE", "-D_UNICODE", "-DWIN32_LEAN_AND_MEAN" };
    const sources = .{
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
        "xalloc.c",
    };

    exe.addCSourceFiles(&sources, &flags);

    exe.linkLibC();
    exe.linkSystemLibrary("setupapi");
    exe.linkSystemLibrary("hid");
    exe.linkSystemLibrary("comctl32");
    exe.linkSystemLibrary("gdi32");

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run cracken");
    run_step.dependOn(&run_exe.step);
}
