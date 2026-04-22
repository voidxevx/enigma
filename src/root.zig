const std = @import("std");
const test_struct = @import("test/test.zig");
const Objects = @import("interpreter/objects.zig");
const interpreter = @import("interpreter/interpreter.zig");

comptime {
    _ = test_struct.use_test;
    _ = Objects.test_objects;
    _ = interpreter.new_interpreter;
    _ = interpreter.destroy_interpreter;
}

export fn zig_test() void {
    std.debug.print("Hello from zig!\n", .{});
}
