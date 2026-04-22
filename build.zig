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

    lib.linkLibC();
    lib.addIncludePath(b.path("src/"));

    b.installArtifact(lib);

    // const c_lib = b.addLibrary(.{
    //     .linkage = .dynamic,
    //     .name = "enigma",
    //     .root_module = b.addModule("enigma", .{
    //         .optimize = optimize,
    //         .target = target,
    //     }),
    // });

    // c_lib.linkLibC();
    // c_lib.linkLibCpp();
    // c_lib.addCSourceFiles(.{ .files = &.{
    //     "src/test.c",
    // }, .flags = &.{"-std=c17"} });

    // c_lib.addCSourceFiles(.{ .files = &.{
    //     "src/test.cpp",
    // }, .flags = &.{"-std=c++17"} });

    // b.installArtifact(c_lib);

    const tests = b.addTest(.{
        .root_module = mod,
    });

    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&tests.step);
}
