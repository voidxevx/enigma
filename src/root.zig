const std = @import("std");
const Objects = @import("interpreter/objects.zig");
const interpreter = @import("interpreter/interpreter.zig");

comptime {
    _ = interpreter.new_interpreter;
    _ = interpreter.destroy_interpreter;
    _ = interpreter.push_to_interpreter;
    _ = interpreter.pop_from_interpreter;
    _ = interpreter.flush_interpreter;
}
