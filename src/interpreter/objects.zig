const std = @import("std");

pub const Object = extern union {
    int: i32,
    uint: u32,
    long: i64,
    ulong: u64,
    float: f32,
    double: f64,
};

pub export fn test_objects(obj: Object) void {
    std.debug.print("object int value: {d}\n", .{obj.int});
}
