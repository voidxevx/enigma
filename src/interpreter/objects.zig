const std = @import("std");

pub const IdentifierHash = u64;

pub const Object = extern union {
    int: i32,
    uint: u32,
    long: i64,
    ulong: u64,
    float: f32,
    double: f64,

    identifier: IdentifierHash,
};

