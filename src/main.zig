
// INCLUDES -----
const std = @import("std");
const enigma = @import("enigma");
// ----- INCUDES

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var operators: std.ArrayList(enigma.Operator) = .empty;
    try operators.append(gpa, .{
        .symbol = '+',
        .infix_binding_power = 3,
    });

    const t_stream = try enigma.TokenStream.init(gpa, .{ .operators = operators }, "x + 1");

    std.debug.print("{f}", .{t_stream});
}