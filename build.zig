//! Zig Build Script
//! 4/22/2026 - Nyx

// INCLUDES -----
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("enigma-core", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "enigma-core",
        .root_module = mod,
    });

    b.installArtifact(lib);

    const tests = b.addTest(.{
        .root_module = mod,
    });

    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&tests.step);
}
