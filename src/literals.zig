//! # Literals
//! 4/17/2026 - Nyx
//! 
//! Literal values: integers, booleans, strings, etc.

pub const ObjectLiteral = union(enum) {
    byte: i8,
    ubyte: u8,

    short: i16,
    ushort: u16,

    int: i32,
    uint: u32,

    long: i64,
    ulong: u64,

    size: usize,

    float: f32,
    double: f64,

    string: []const u8,
    bool: bool,

    pub fn format(
        self: ObjectLiteral,
        writer: anytype
    ) !void {
        switch (self) {
            .byte => |byte| try writer.print("{d}i8", .{byte}),
            .ubyte => |ubyte| try writer.print("{d}u8", .{ubyte}),
            .short => |short| try writer.print("{d}i16", .{short}),
            .ushort => |ushort| try writer.print("{d}u16", .{ushort}),
            .int => |int| try writer.print("{d}i32", .{int}),
            .uint => |uint| try writer.print("{d}u32", .{uint}),
            .long => |long| try writer.print("{d}i64", .{long}),
            .ulong => |ulong| try writer.print("{d}u64", .{ulong}),
            .size => |size| try writer.print("{d}usize", .{size}),
            .float => |float| try writer.print("{d}f32", .{float}),
            .double => |double| try writer.print("{d}f64", .{double}),
            .string => |str| try writer.print("{s}", .{str}),
            .bool => |_bool| try writer.print("{}", .{_bool}),
        }
    }
};