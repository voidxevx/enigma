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
