// INCLUDES -----
const std = @import("std");
const enigma = @import("enigma");
// ----- INCUDES

const TITLE_CARD: []const u8 = 
\\ ====================================================================== 
\\   _____                     ______
\\  /@    \___________________/      \               
\\  \  @                              \
\\  / @                           -----| - - - - 
\\ |   @   __________________         /
\\  \_____/                  \_______/
\\                            
\\ ====================================================================== 
;

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


    var pinar_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&pinar_buffer);
    var stdout = &stdout_writer.interface;

    try stdout.print("{s}", .{TITLE_CARD});
    try stdout.flush();
}
