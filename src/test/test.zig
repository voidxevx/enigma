const std = @import("std");

pub const TestStruct = extern struct {
    data: u64,
};

pub export fn use_test(st: *const TestStruct) void {
    std.debug.print("test struct data: {d}\n", .{st.data});
}
