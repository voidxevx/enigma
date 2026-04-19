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

    try operators.append(gpa, .{
        .symbol = '*',
        .infix_binding_power = 4,
    });

    const t_stream = try enigma.TokenStream.init(gpa, .{ .operators = operators }, "x + 1 * 7 + 8");

    std.debug.print("{f}\n", .{t_stream});

    var ast = try enigma.SyntaxTree.init(gpa, t_stream);
    defer ast.deinit(gpa);
    std.debug.print("{f}", .{ast});
}
