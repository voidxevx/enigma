//! Interpreter Register
//! 4/25/2026 - Nyx

// INCLUDES -----
const Ord = @import("../../core.zig").Ord;

/// Interface Register
/// 
/// Ambiguous register that packs a pointer to the register, its size, and a vtable.
/// This is use registers without having to pass a generic size for the register into a function. 
pub const IRegister = struct {
    ptr: *anyopaque,
    size: usize,
    vtable: *const VTable,

    const VTable = struct {
        memory: *const fn(*anyopaque) []const u8,
        mov: *const fn(*anyopaque, []const u8) anyerror!void,
        flush: *const fn(*anyopaque) void,
    };

    /// Returns a slice containing the raw memory in the register.
    inline fn memory(self: IRegister) []const u8 {
        return self.vtable.memory(self.ptr);
    }

    /// Moves data into the register.
    pub inline fn mov(self: IRegister, mem: []const u8) anyerror!void {
        try self.vtable.mov(self.ptr, mem);
    }

    pub inline fn flush(self: IRegister) void {
        self.vtable.flush(self.ptr);
    }
};


/// Register
/// 
/// Stores raw bytes in a way that can be quickly accessed.
/// Registers can only have 1, 2, 4, 8, or 16 bytes.
/// The register can be rentinterpreted in any form that matches the 
/// byte size. Attempting to reinterpret as a type larger than the register will
/// result in a compiler error.
pub fn Register(comptime size: usize) type {
    if (size != 1 and size != 2 and size != 4 and size != 8 and size != 16)
        @compileError("Registers can only be 8, 16, 32, 64, or 128 bits");

    return struct {
        raw: Raw,

        pub const Raw = extern union {
            bytes: [size]u8,

            i8: i8,
            u8: u8,
            bool: bool,
            ord: Ord,

            i16: if (size >= 2) i16 else void,
            u16: if (size >= 2) u16 else void,

            i32: if (size >= 4) i32 else void,
            u32: if (size >= 4) u32 else void,
            f32: if (size >= 4) f32 else void,

            usize: if (size >= @sizeOf(usize)) usize else void,

            i64: if (size >= 8) i64 else void,
            u64: if (size >= 8) u64 else void,
            f64: if (size >= 8) f64 else void,

            i128: if (size >= 16) i128 else void,
            u128: if (size >= 16) u128 else void,
            f128: if (size >= 16) f128 else void,
        };

        pub inline fn empty() Register(size) {
            return .{
                .raw = .{ .bytes = [_]u8{0} ** size },
            };
        }

        /// Packs the register into an interface
        pub fn interface(self: *Register(size)) IRegister {
            return .{
                .ptr = self,
                .size = size,
                .vtable = &.{
                    .memory = Register(size).interface_memory,
                    .mov = Register(size).interface_mov,
                    .flush = Register(size).interface_flush,
                }
            };
        }

        fn interface_memory(ptr: *anyopaque) []const u8 {
            const self: *Register(size) = @ptrCast(@alignCast(ptr));
            return &self.raw.bytes;
        }

        fn interface_mov(ptr: *anyopaque, mem: []const u8) anyerror!void {
            const self: *Register(size) = @ptrCast(@alignCast(ptr));
            try self.mov_unsized(mem);
        }

        fn interface_flush(ptr: *anyopaque) void {
            const self: *Register(size) = @ptrCast(@alignCast(ptr));
            self.flush();
        }
        
        /// Moves data matching the size of the register into the register.
        /// For types that don't exactly match the size of the register use: `move_unsized`
        pub inline fn mov(self: *Register(size), mem: [size]u8) void {
            @memmove(&self.*.raw.bytes, &mem);
        }

        /// Moves data of any size into the registers. If the data is larger than the register it will 
        /// return an error.
        pub inline fn mov_unsized(self: *Register(size), mem: []const u8) error{DataTooLarger}!void {
            if (mem.len > size) 
                return error.DataTooLarger;
            @memmove(self.raw.bytes[0..mem.len], mem);
        }

        /// Copies the data of one register into another. The source register must
        /// be smaller or equal in size to the destination register.
        pub inline fn copy(self: *Register(size), other: IRegister) error{RegisterTooLarge}!void {
            if (other.size > size)
                return error.RegisterTooLarge;
            @memmove(self.*.raw.bytes[0..other.size], other.memory());
        }

        /// Clears the register filling it with 0s
        pub inline fn flush(self: *Register(size)) void {
            self.*.raw.bytes = [_]u8{0} ** size;
        }
    };
}


/// A register that holds most data types or pointers.
/// This will always match the systems pointer size.
pub const PrimaryRegister = Register(@sizeOf(usize));

/// Used for large registers like ymm or xmm.
pub const LargeRegister = Register(16);

/// Used for small integers and chars
pub const SmallRegister = Register(1);