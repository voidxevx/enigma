// INCLUDES -----
const std = @import("std");
const enigma = @import("enigma");
// ----- INCUDES

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    const operators = try enigma.default_operators(gpa);    
    var tokens = try enigma.TokenStream.init(gpa, "(2 + 7) * 8 / 4", .{ .operators = operators});
    defer tokens.deinit(gpa);

    std.debug.print("{f}\n", .{tokens});

    var ast = try enigma.SyntaxTree.init(gpa, tokens);
    std.debug.print("{f}\n", .{ast});

    var interpreter = try enigma.Interpreter.init(gpa);
    const result = try interpreter.run(&ast);

    if (result) |res| {
        std.debug.print("Result: {f}\n", .{res});
    }
}
