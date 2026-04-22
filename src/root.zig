const std = @import("std");
const test_struct = @import("test/test.zig");

comptime {
    _ = test_struct.use_test;
}

export fn zig_test() void {
    std.debug.print("Hello from zig!\n", .{});
}