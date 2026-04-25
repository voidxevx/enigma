//! File Builder
//! 4/25/2026 - Nyx

const std = @import("std");
const TokenStream = @import("token-stream.zig").TokenStream;
const SyntaxTree = @import("parser.zig").SyntaxTree;
const core = @import("../core.zig");

pub fn build_file(path: []const u8, gpa: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const buffer = try std.fs.cwd().readFileAlloc(gpa, path, 4096);
    defer gpa.free(buffer);

    var stream = try TokenStream.init(
        gpa, 
        .{
            .operators = &.{},
            .keywords = &.{}
        }, 
        &buffer
    );
    defer stream.deinit(gpa);

    std.debug.print("{f}", .{stream});
}

pub export fn test_file_builder() void {
    build_file("test.eng", core.allocator) catch @panic("Failed to build file");
}