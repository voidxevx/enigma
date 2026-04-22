const std = @import("std");
const core = @import("../core.zig");
const objects = @import("objects.zig");
const c = std.c;

pub const Interpreter = struct {
    const DEFAULT_STACK_CAPACITY: usize = 16;

    stack: [*c]objects.Object,
    stack_ptr: usize = 0,
    stack_capacity: usize = DEFAULT_STACK_CAPACITY,

    pub fn init() !*Interpreter {
        const stack = try core.allocator.alloc(objects.Object, DEFAULT_STACK_CAPACITY);
        var interpreter = try core.allocator.create(Interpreter);
        interpreter.stack = stack.ptr;

        return interpreter;
    }

    pub fn deinit(self: *Interpreter) void {
        core.allocator.free(self.stack[0..self.stack_capacity]);
        core.allocator.destroy(self);
    }
};

pub export fn new_interpreter() *Interpreter {
    return Interpreter.init() catch @panic("Failed to create interpreter context");
}

pub export fn destroy_interpreter(interpreter: *Interpreter) void {
    interpreter.deinit();
}
