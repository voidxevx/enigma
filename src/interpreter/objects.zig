//! # Objects
//! 4/22/2026 - Nyx
//! 
//! An identical Rust implementation can be found at: ./objects.rs

// INCLUDES -----
const std = @import("std");

/// Hashed Identifier
/// 
/// An identifier that was hashed into a smaller sequence to allow for more efficient memory management.
pub const IdentifierHash = usize;

/// Interpreter Object
/// 
/// 8byte union of all possible types that an object stored by the interpreter can take.
/// The exact type that the object manifests as cannot be determined at runtime so compile time
/// type checks are required.
pub const Object = extern union {
    byte: i8,
    ubyte: u8,
    short: i16,
    ushort: u16,
    int: i32,
    uint: u32,
    long: i64,
    ulong: u64,
    float: f32,
    double: f64,

    /// Identifier
    /// 
    /// Works as either a variable name or a pointer
    identifier: IdentifierHash,


    pub fn format(self: *const Object, writer: *std.io.Writer) std.Io.Writer.Error!void {
        _ = self;
        try writer.print("LIT", .{});
        // switch (self.*) {
        //     .byte => |i| try writer.print("{d}", .{i}),
        //     .ubyte => |i| try writer.print("{d}", .{i}),
        //     .short => |i| try writer.print("{d}", .{i}),
        //     .ushort => |i| try writer.print("{d}", .{i}),
        //     .int => |i| try writer.print("{d}", .{i}),
        //     .uint => |i| try writer.print("{d}", .{i}),
        //     .long => |i| try writer.print("{d}", .{i}),
        //     .ulong => |i| try writer.print("{d}", .{i}),
        //     .float => |i| try writer.print("{d}", .{i}),
        //     .double => |i| try writer.print("{d}", .{i}),
        //     .identifier => |i| try writer.print("{d}", .{i}),
        // }
    }
};

