//! Interpreter Stack Memory
//! 4/25/2026

// INCLUDES -----
const std = @import("std");
const register = @import("register.zig");
const Register = register.Register;
const IRegister = register.IRegister;
const HeapMemory = @import("heap.zig").HeapMemory;
// ----- INCLUDES

/// Interpreter Stack
/// 
/// Continues stack of memory read and written too by the interpreter.
pub const Stack = struct {
    /// The size of the stack (in bytes)
    const STACK_SIZE: usize = 1024;

    memory: []u8,
    /// The current top position of the stack
    stack_ptr: register.PrimaryRegister = .{ .raw = .{ .usize = 0 } },

    pub const Error = error{
        StackOverflow,
    };

    pub fn init(gpa: std.mem.Allocator) !Stack {
        return .{
            .memory = try gpa.alloc(u8, STACK_SIZE),
        };
    }

    pub fn deinit(self: *Stack, gpa: std.mem.Allocator) void {
        gpa.free(self.memory);
    }

    /// Pushes memory onto the stack
    pub fn push(self: *Stack, mem: []const u8) Error!void {
        if (self.stack_ptr.raw.usize + mem.len > STACK_SIZE)
            return Error.StackOverflow;
        @memmove(self.*.memory[self.stack_ptr.raw.usize..self.stack_ptr.raw.usize+mem.len], mem);
        self.*.stack_ptr.raw.usize += mem.len;
    }

    /// Pops bytes from the stack into a register.
    pub fn pop(self: *Stack, bytes: usize, reg: IRegister) !void {
        try reg.mov(self.memory[self.stack_ptr.raw.usize-bytes..self.stack_ptr.raw.usize]);
        self.*.stack_ptr.raw.usize -= bytes;
    }

    /// Reads a slice of the stack
    pub fn read(self: *Stack, ptr: usize, bytes: usize) []const u8 {
        return self.memory[ptr..ptr+bytes];
    }

    /// Writes a slice of memory to the stack
    pub fn write(self: *Stack, ptr: usize, mem: []const u8) void {
        @memmove(self.memory[ptr..ptr+mem.len], mem);
    }
};

pub export fn test_stack() void {
    var stack = Stack.init(std.heap.page_allocator) catch @panic("failed to create stack");
    defer stack.deinit(std.heap.page_allocator);

    const r: Register(4) = .{ .raw = .{ .i32 = 32 } };
    stack.push(&r.raw.bytes) catch @panic("failed to push to stack");

    var r2: Register(4) = .{ .raw = .{ .i32 = 0 }};
    stack.pop(4, r2.interface()) catch @panic("failed to pop from stack");

    std.debug.assert(r2.raw.i32 == 32);



    var r3: Register(2) = .{ .raw = .{ .u16 = 0 } };
    var r4: Register(1) = .{ .raw = .{ .u8 = 75 } };
    r3.copy(r4.interface()) catch @panic("can't copy register");

    std.debug.assert(r3.raw.u8 == 75);


    var heap = HeapMemory.init(std.heap.page_allocator) catch @panic("failed to create heap");
    const ptr = heap.allocate(4) catch @panic("failed to allocate");

    var r5: Register(4) = .{ .raw = .{ .u32 = 0 } };
    r5.mov_unsized(heap.get(ptr)) catch unreachable;
    std.debug.print("allocated memory: {d}\n", .{ r5.raw.u32 });

    heap.free(ptr) catch unreachable;
}
