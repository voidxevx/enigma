// INCLUDES -----
const std = @import("std");
const enigma = @import("enigma");
// ----- INCUDES

fn sum(interpreter: *enigma.Interpreter) anyerror!void {
    const r = interpreter.pop();
    const l = interpreter.pop();

    if (l) |l_val| 
    if (r) |r_val| {
        try interpreter.push(l_val + r_val);
    };
}

fn product(interpreter: *enigma.Interpreter) anyerror!void {
    const r = interpreter.pop();
    const l = interpreter.pop();

    if (l) |l_val| 
    if (r) |r_val| {
        try interpreter.push(l_val * r_val);
    };
}

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var operators: std.ArrayList(enigma.NEW_Operator) = .empty;
    try operators.append(gpa, .{
        .symbol = ",",
        .infix_binding_power = 2,
        .resolve = sum,
    });

    var tokenizer = try enigma.NEW_TokenStream.Tokenizer.init("testing 1, 2, 3", .{ .operators = operators }, gpa);
    try tokenizer.tokenize();
    var tokens = try tokenizer.finish();
    defer tokens.deinit(gpa);

    std.debug.print("token count: {d}\n", .{tokens.token_count});
    for (0..tokens.token_count) |i| {
        const token = tokens.tokens[i];
        std.debug.print("{d} {f}\n", .{i, token});
    }

    // var operators: std.ArrayList(enigma.Operator) = .empty;
    // try operators.append(gpa, .{
    //     .symbol = '+',
    //     .infix_binding_power = 3,
    //     .resolve = sum,
    // });

    // try operators.append(gpa, .{
    //     .symbol = '*',
    //     .infix_binding_power = 4,
    //     .resolve = product,
    // });

    // const t_stream = try enigma.TokenStream.init(gpa, .{ .operators = operators }, "3 + 9 * 4");

    // std.debug.print("{f}\n", .{t_stream});

    // var ast = try enigma.SyntaxTree.init(gpa, t_stream);
    // defer ast.deinit(gpa);
    // std.debug.print("{f}\n", .{ast});

    // var interpreter: enigma.Interpreter = try .init(gpa);
    // const result = try interpreter.run(&ast);

    // if (result) |res|
    //     std.debug.print("Result: {d}", .{res});
}
