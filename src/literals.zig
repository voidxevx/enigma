
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

};