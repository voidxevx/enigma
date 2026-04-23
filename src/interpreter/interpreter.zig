const std = @import("std");
const core = @import("../core.zig");
const objects = @import("objects.zig");
const heap = @import("heap-sparse-set.zig");

pub const Interpreter = struct {
    const DEFAULT_STACK_CAPACITY: usize = 16;

    stack: []objects.Object,
    stack_ptr: usize,
    stack_capacity: usize,


    heap: heap.HeapSparseSet,

    pub fn init() !*Interpreter {
        const stack = try core.allocator.alloc(objects.Object, DEFAULT_STACK_CAPACITY);
        var interpreter = try core.allocator.create(Interpreter);
        interpreter.stack = stack;
        interpreter.stack_capacity = DEFAULT_STACK_CAPACITY;
        interpreter.stack_ptr = 0;
        interpreter.heap = try heap.HeapSparseSet.init(core.allocator);

        return interpreter;
    }

    pub fn deinit(self: *Interpreter) void {
        core.allocator.free(self.stack[0..self.stack_capacity]);
        self.heap.deinit();
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

    pub fn allocate(self: *Interpreter, data: objects.Object) !objects.IdentifierHash {
        return self.heap.emplace(data);
    }

    pub fn free(self: *Interpreter, id: objects.IdentifierHash) !void {
        try self.heap.free(id);
    }

    pub fn get(self: *const Interpreter, id: objects.IdentifierHash) *const objects.Object {
        return self.heap.get(id);
    }

    pub fn get_mut(self: *Interpreter, id: objects.IdentifierHash) *objects.Object {
        return self.heap.get_mut(id);
    }
};

pub export fn new_interpreter() *Interpreter { return Interpreter.init() catch @panic("Failed to create interpreter context"); }
pub export fn destroy_interpreter(interpreter: *Interpreter) void { interpreter.deinit(); }
pub export fn push_to_interpreter(interpreter: *Interpreter, data: objects.Object) void { interpreter.push(data) catch @panic("failed to push to interpreter stack"); }
pub export fn pop_from_interpreter(interpreter: *Interpreter) objects.Object { return interpreter.pop(); }
pub export fn flush_interpreter(interpreter: *Interpreter) void { interpreter.flush() catch @panic("failed to flush stack"); }
pub export fn interpreter_allocate(interpreter: *Interpreter, data: objects.Object) objects.IdentifierHash { return interpreter.allocate(data) catch @panic("failed to allocate interpreter memory"); }
pub export fn interpreter_free(interpreter: *Interpreter, id: objects.IdentifierHash) void { interpreter.free(id) catch @panic("failed to free interpreter heap memory"); }
pub export fn interpreter_get(interpreter: *const Interpreter, id: objects.IdentifierHash) *const objects.Object { return interpreter.get(id); }
pub export fn interpreter_get_mut(interpreter: *Interpreter, id: objects.IdentifierHash) *objects.Object { return interpreter.get_mut(id); }