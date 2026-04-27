//! Interpreter Heap Memory
//! 4/25/2026 - Nyx

// INCLUDES -----
const std = @import("std");

/// Interpreter Dynamic Memory
/// 
/// Allocates partitions of memory that can be read/written too.
pub const HeapMemory = struct {
    const DEFAULT_SET_SIZE: usize = 16;
    
    gpa: std.mem.Allocator,

    allocations: [][]u8,
    allocation_count: usize = 0,
    allocation_capacity: usize = DEFAULT_SET_SIZE,

    free_allocations: []usize,
    freed_count: usize = 0,
    freed_capacity: usize = DEFAULT_SET_SIZE,

    pub fn init(gpa: std.mem.Allocator) !HeapMemory {
        return .{
            .gpa = gpa,
            .allocations = try gpa.alloc([]u8, DEFAULT_SET_SIZE),
            .free_allocations = try gpa.alloc(usize, DEFAULT_SET_SIZE),
        };
    }

    /// Pushes a pointer onto the freed allocations stack
    fn push_freed(self: *HeapMemory, ptr: usize) !void {
        if (self.freed_count >= self.freed_capacity) {
            self.*.freed_capacity *= 2;
            self.*.free_allocations = try self.gpa.realloc(self.free_allocations, self.freed_capacity);
        }

        self.*.free_allocations[self.freed_count] = ptr;
        self.*.freed_count += 1;
    }

    /// Pops a previously freed pointer off of the freed stack to be reused
    fn pop_freed(self: *HeapMemory) ?usize {
        if (self.freed_count == 0)
            return null;

        self.*.freed_count -= 1;
        return self.free_allocations[self.freed_count];
    }

    /// Allocates a list of bytes for the interpreter
    pub fn allocate(self: *HeapMemory, bytes: usize) !usize {
        const ptr = if (self.pop_freed()) |ptr| ptr else new_ptr: {
            if (self.allocation_count >= self.allocation_capacity) {
                self.*.allocation_capacity *= 2;
                self.*.allocations = try self.gpa.realloc(self.allocations, self.allocation_capacity);
            }

            defer self.*.allocation_count += 1;
            break :new_ptr self.allocation_count;
        };

        self.*.allocations[ptr] = try self.gpa.alloc(u8, bytes);
        return ptr;
    }

    /// Reallocates a string of bytes allowing it to be resized
    pub inline fn reallocate(self: *HeapMemory, ptr: usize, new_size: usize) !void {
        try self.gpa.realloc(self.*.allocations[ptr], new_size);
    }

    /// Frees an allocated string of memory
    pub fn free(self: *HeapMemory, ptr: usize) !void {
        self.gpa.free(self.*.allocations[ptr]);
        try self.push_freed(ptr);
    }

    /// Gets an allocated slice of memory
    pub fn get(self: *HeapMemory, ptr: usize) []u8 {
        return self.allocations[ptr];
    }



    pub fn format(self: *const HeapMemory, writer: *std.io.Writer) std.Io.Writer.Error!void {
        try writer.print("[HEAP]\n\tAllocations: {d}\n", .{self.allocation_count - self.freed_count});
    }
};