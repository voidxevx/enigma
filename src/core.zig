//! # Zig Core
//! 4/22/2026 - Nyx
//! 
//! Core global objects

const std = @import("std");

/// Global allocator
/// 
/// Since sending an allocator across the ffi is messy it is 
/// moved into a global scope. In most cases that don't involve the 
/// ffi the allocator will be passed as usual but still referencing the global
/// allocator
pub const allocator: std.mem.Allocator = std.heap.page_allocator;


/// Comparison result ordering
/// 
/// Stores the result flag after a comparison operator.
/// Uses a bit-field allowing `l | eq = le` or `if (cmp & ge == cmp)`
/// to be used to check multiple types with one comparison.
/// 
/// For field comparison use the constants Ord.Eq which are the comptime int variants.
/// ```
/// const order = cmp(i32, 56, 90);
/// if (order.i() & Ord.Ge == order.()) {
///     // Greater or Equal
/// } else {
///     // Less
/// }
/// ```
/// 
/// The enum only uses 3 bits but has a padding of 5 bits to fit in an 8 bit register.
pub const Ord = enum(u8) {
    pub const Eq = 0b001;
    pub const L = 0b010;
    pub const G = 0b100;
    pub const Le = 0b011;
    pub const Ge = 0b101;
    pub const Ne = 0b110;

    null = 0b000,

    /// Equal
    eq = 0b001,
    /// Less
    l = 0b010,
    /// Greater
    g = 0b100,

    /// Less than or equal
    le = 0b011,
    /// Greater than or equal
    ge = 0b101,  
    /// Not equal (less and greater)
    ne = 0b110,

    /// Converts the ordering into its int value
    pub inline fn i(self: Ord) u8 {
        return @intFromEnum(self);
    }

    pub fn format(self: Ord, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .null => try writer.print("NULL ORDER", .{}),
            .eq => try writer.print("==", .{}),
            .l => try writer.print("<", .{}),
            .g => try writer.print(">", .{}),
            .le => try writer.print("<=", .{}),
            .ge => try writer.print(">=", .{}),
            .ne => try writer.print("!=", .{}),
        }
    }
};

/// Compares to value returning their ordering.
/// 
/// For non-primitive types the .cmp method will be called expecting a ordering as its result.
/// Should never return Ne, Ge, Le, null.
pub fn cmp(comptime T: type, a: T, b: T) Ord {
    switch (@typeInfo(T)) {
        .int, .float => {
            if (a > b) {
                return .g;
            } else if (a < b) {
                return .l;
            } else {
                return .eq;
            }
        },

        else =>
            return a.cmp(b),
    }
}
