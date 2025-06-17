const std = @import("std");

pub fn build(b: *std.Build) !void {
    const mode = b.standardOptimizeOption(.{});
    const tgt = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
        },
    });

    const mod = b.addModule("cracken", .{
        .root_source_file = b.path("cracken.zig"),
        .target = tgt,
        .optimize = mode,
    });
    const exe = b.addExecutable(.{
        .name = "cracken",
        .root_module = mod,
        .win32_manifest = b.path("cracken.manifest"),
    });

    if (mode != .Debug) {
        exe.subsystem = .Windows;
        exe.want_lto = true;
    }

    const flags = .{ "-DUNICODE", "-D_UNICODE", "-DWIN32_LEAN_AND_MEAN" };
    const sources = .{
        "krakenwidget.c",
        "mainwindow.c",
        "window.c",
    };

    exe.addCSourceFiles(.{ .files = &sources, .flags = &flags });

    exe.linkLibC();
    exe.linkSystemLibrary("setupapi");
    exe.linkSystemLibrary("hid");
    exe.linkSystemLibrary("comctl32");
    exe.linkSystemLibrary("gdi32");

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run cracken");
    run_step.dependOn(&run_exe.step);

    const check_exe = b.addExecutable(.{
        .name = "cracken_check",
        .root_module = mod,
    });
    const check_step = b.step("check", "Check compiler");
    check_step.dependOn(&check_exe.step);
}
