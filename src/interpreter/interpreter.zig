const std = @import("std");
const core = @import("../core.zig");
const objects = @import("objects.zig");

pub const Interpreter = struct {
    const DEFAULT_STACK_CAPACITY: usize = 16;

    stack: []objects.Object,
    stack_ptr: usize,
    stack_capacity: usize,

    pub fn init() !*Interpreter {
        const stack = try core.allocator.alloc(objects.Object, DEFAULT_STACK_CAPACITY);
        var interpreter = try core.allocator.create(Interpreter);
        interpreter.stack = stack;
        interpreter.stack_capacity = DEFAULT_STACK_CAPACITY;
        interpreter.stack_ptr = 0;

        return interpreter;
    }

    pub fn deinit(self: *Interpreter) void {
        core.allocator.free(self.stack[0..self.stack_capacity]);
        core.allocator.destroy(self);
    }

    pub fn push(self: *Interpreter, data: objects.Object) !void {
        if (self.stack_ptr >= self.stack_capacity) {
            self.*.stack_capacity *= 2;
            self.stack = try core.allocator.realloc(self.stack, self.stack_capacity);
        }

        self.*.stack[self.stack_ptr] = data;
        self.*.stack_ptr += 1;
    }

    pub fn pop(self: *Interpreter) objects.Object {
        self.stack_ptr -= 1;
        return self.stack[self.stack_ptr];
    }

    pub fn flush(self: *Interpreter) !void {
        self.*.stack = try core.allocator.realloc(self.stack, DEFAULT_STACK_CAPACITY);
        self.*.stack_ptr = 0;
        self.*.stack_capacity = DEFAULT_STACK_CAPACITY;
    }
};

pub export fn new_interpreter() *Interpreter {
    return Interpreter.init() catch @panic("Failed to create interpreter context");
}

pub export fn destroy_interpreter(interpreter: *Interpreter) void {
    interpreter.deinit();
}

pub export fn push_to_interpreter(interpreter: *Interpreter, data: objects.Object) void {
    interpreter.push(data) catch @panic("failed to push to interpreter stack");
}

pub export fn pop_from_interpreter(interpreter: *Interpreter) objects.Object {
    return interpreter.pop();
}

pub export fn flush_interpreter(interpreter: *Interpreter) void {
    interpreter.flush() catch @panic("failed to flush stack");
}