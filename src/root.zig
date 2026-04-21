const std = @import("std");

export fn zig_test() void {
    std.debug.print("Hello from zig!\n", .{});
}