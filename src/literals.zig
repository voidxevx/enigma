
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
            .byte => |byte| try writer.print("{d}", .{byte}),
            .ubyte => |ubyte| try writer.print("{d}", .{ubyte}),
            .short => |short| try writer.print("{d}", .{short}),
            .ushort => |ushort| try writer.print("{d}", .{ushort}),
            .int => |int| try writer.print("{d}", .{int}),
            .uint => |uint| try writer.print("{d}", .{uint}),
            .long => |long| try writer.print("{d}", .{long}),
            .ulong => |ulong| try writer.print("{d}", .{ulong}),
            .size => |size| try writer.print("{d}", .{size}),
            .float => |float| try writer.print("{d}", .{float}),
            .double => |double| try writer.print("{d}", .{double}),
            .string => |str| try writer.print("{s}", .{str}),
            .bool => |_bool| try writer.print("{}", .{_bool}),
        }
    }
};