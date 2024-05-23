const std = @import("std");
const mem = std.mem;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const example = b.option(bool, "example", "Build example") orelse false;

    const mod = b.addModule("escalator", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("lib/root.zig"),
    });

    addDocsStep(b, .{ .target = target, .optimize = optimize });

    if (example) {
        const exe = b.addExecutable(.{
            .name = "escalate",
            .root_source_file = b.path("examples/escalate.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("escalator", mod);
        b.installArtifact(exe);
    }
}

fn addDocsStep(b: *std.Build, options: anytype) void {
    const docs_step = b.step("docs", "Emit docs");

    const lib = b.addStaticLibrary(.{
        .name = "escalator",
        .root_source_file = b.path("lib/root.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });

    docs_step.dependOn(&docs_install.step);
}
