//! # Interpreter 
//! 4/22/2026 - Nyx
//! 
//! The interpreter is not exactly the interpreter. The interpreter is designed 
//! to be passed around during execution to handle dynamically allocated memory and
//! to store quick access data for computations. The interpreter doesn't directly 
//! execute and commands.
//! 
//! The Interpreter has a stack array and a HeapSparseSet to emulate that of a CPU.

// INCLUDES -----
const std = @import("std");
const core = @import("../core.zig");
const heap = @import("heap-sparse-set.zig");
// ----- INCLUDES

// MODULES ----
pub const objects = @import("objects.zig");
pub const lexics = @import("token-stream.zig");
// ----- MODULES

/// Runtime Interpreter Memory handler
/// 
/// Handles the dynamic memory allocations for 
/// the interpreted bytecode.
/// 
/// # Example
/// 
/// ## Zig:
/// ```zig
/// const Interpreter = @import("interpreter.zig");
/// 
/// var interpreter: Interpreter = try .init();
/// defer interpreter.deinit();
/// 
/// try interpreter.push(.{.int = 90});
/// const val = interpreter.pop().?;
/// 
/// const id = try interpreter.allocate(val);
/// 
/// const ptr = interpreter.get(id);
/// ```
/// 
/// ## Rust:
/// 
/// ```rust
/// use enigma::interpreter::{objects::Object, Interpreter};
/// 
/// let mut interpreter = Interpreter::new();
/// interpreter.push(Object { int: 90});
/// let val = interpreter.pop().unwrap();
/// 
/// let id = interpreter.allocate(val);
/// 
/// let ptr: &Object = interpreter.get(id);
/// ```
pub const Interpreter = struct {

    /// The Default capacity given to the stack
    const DEFAULT_STACK_CAPACITY: usize = 16;

    /// The Data of the stack
    stack: []objects.Object,
    /// Pointer to the top of the stack
    stack_ptr: usize,
    /// The current capacity of the stack
    stack_capacity: usize,

    /// The heap sparse set
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

    /// Pushes an object to the top of the stack
    /// 
    /// # Example
    /// 
    /// ```zig
    /// const Interpreter = @import("interpreter.zig").Interpreter;
    /// 
    /// var interpreter: *Interpreter = try .init();
    /// defer interpreter.deinit();
    /// 
    /// try interpreter.push(.{.int = 50});
    /// ```
    pub fn push(self: *Interpreter, data: objects.Object) !void {
        if (self.stack_ptr >= self.stack_capacity) {
            self.*.stack_capacity *= 2;
            self.stack = try core.allocator.realloc(self.stack, self.stack_capacity);
        }

        self.*.stack[self.stack_ptr] = data;
        self.*.stack_ptr += 1;
    }

    /// Pops an object from the top of the stack
    /// 
    /// This doesn't check for if the stack is currently empty
    /// so the existence of an object must be predetermined as true.
    /// Use .pop to get an optional version.
    /// 
    /// # Example
    /// 
    /// ```zig
    /// const Interpreter = @import("interpreter.zig").Interpreter;
    /// 
    /// var interpreter: *Interpreter = try .init();
    /// defer interpreter.deinit();
    /// 
    /// try interpreter.push(.{.int = 50});
    /// 
    /// const data: object.Object = interpreter.raw_pop();
    /// ```
    pub fn raw_pop(self: *Interpreter) objects.Object {
        self.stack_ptr -= 1;
        return self.stack[self.stack_ptr];
    }

    /// Pops an object from the top of the stack
    /// 
    /// # Example
    /// 
    /// ```zig
    /// const Interpreter = @import("interpreter.zig").Interpreter;
    /// 
    /// var interpreter: *Interpreter = try .init();
    /// defer interpreter.deinit();
    /// 
    /// try interpreter.push(.{.int = 50});
    /// 
    /// const data: object.Object = interpreter.pop().?;
    /// ```
    pub fn pop(self: *Interpreter) ?objects.Object {
        if (self.is_stack_empty())
            return null;

        self.stack_ptr -= 1;
        return self.stack[self.stack_ptr];
    }

    /// Returns whether or not the stack is empty or not. 
    /// 
    /// This is used by .pop in both rust and zig bindings 
    /// to check the stacks status and prevent errors. 
    /// This must be separated because returning an optional 
    /// isn't possible across FFIs.
    pub fn is_stack_empty(self: *const Interpreter) bool {
        return self.stack_ptr == 0;
    }

    /// Flushes the stack removing all data and resetting its capacity 
    pub fn flush(self: *Interpreter) !void {
        self.*.stack = try core.allocator.realloc(self.stack, DEFAULT_STACK_CAPACITY);
        self.*.stack_ptr = 0;
        self.*.stack_capacity = DEFAULT_STACK_CAPACITY;
    }

    /// Moves a piece of data into the heap returning an identifier pointer.
    pub fn allocate(self: *Interpreter, data: objects.Object) !objects.IdentifierHash {
        return self.heap.emplace(data);
    }

    /// Frees a piece of allocated heap memory by its identifier pointer.
    pub fn free(self: *Interpreter, id: objects.IdentifierHash) !void {
        try self.heap.free(id);
    }

    /// Gets an immutable pointer to a heap allocated piece of memory.
    pub fn get(self: *const Interpreter, id: objects.IdentifierHash) *const objects.Object {
        return self.heap.get(id);
    }

    /// Gets a mutable pointer to a heap allocated piece of memory.
    pub fn get_mut(self: *Interpreter, id: objects.IdentifierHash) *objects.Object {
        return self.heap.get_mut(id);
    }
};


// FFI BINDINGS -----
pub export fn new_interpreter() *Interpreter { return Interpreter.init() catch @panic("Failed to create interpreter context"); }
pub export fn destroy_interpreter(interpreter: *Interpreter) void { interpreter.deinit(); }
pub export fn push_to_interpreter(interpreter: *Interpreter, data: objects.Object) void { interpreter.push(data) catch @panic("failed to push to interpreter stack"); }
pub export fn pop_from_interpreter(interpreter: *Interpreter) objects.Object { return interpreter.raw_pop(); }
pub export fn is_interpreter_stack_empty(interpreter: *Interpreter) bool { return interpreter.is_stack_empty(); }
pub export fn flush_interpreter(interpreter: *Interpreter) void { interpreter.flush() catch @panic("failed to flush stack"); }
pub export fn interpreter_allocate(interpreter: *Interpreter, data: objects.Object) objects.IdentifierHash { return interpreter.allocate(data) catch @panic("failed to allocate interpreter memory"); }
pub export fn interpreter_free(interpreter: *Interpreter, id: objects.IdentifierHash) void { interpreter.free(id) catch @panic("failed to free interpreter heap memory"); }
pub export fn interpreter_get(interpreter: *const Interpreter, id: objects.IdentifierHash) *const objects.Object { return interpreter.get(id); }
pub export fn interpreter_get_mut(interpreter: *Interpreter, id: objects.IdentifierHash) *objects.Object { return interpreter.get_mut(id); }
// ----- FFI BINDINGS