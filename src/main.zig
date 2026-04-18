const std = @import("std");
const enigma = @import("enigma");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    var stdout = &stdout_writer.interface;

    const gpa = std.heap.page_allocator;

    var operators: std.ArrayList(enigma.operator.Operator) = .empty;
    defer operators.deinit(gpa);
    try operators.append(gpa, .{
        .symbol = "+",
        .infix_binding_power = 4,
        .prefix_binding_power = 2,
    });

    var package = 
        try enigma
        .lexing
        .parsing
        .tokenize_file(
            gpa, 
            "tests/main.eng",
            &.{.operators = operators}
        );
    
    try stdout.print("{f}", .{package});
    try stdout.flush();

    const head = try enigma.ast.parser.parse_tokens(&package);

    try stdout.print("{f}", .{head});
    try stdout.flush();
}