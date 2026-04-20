// INCLUDES -----
const std = @import("std");
const enigma = @import("enigma");
// ----- INCUDES

const TITLE_CARD: []const u8 = 
\\=====================================================
\\ ▓█████  ███▄    █  ██▓  ▄████  ███▄ ▄███▓ ▄▄▄      
\\▓█   ▀  ██ ▀█   █ ▓██▒ ██▒ ▀█▒▓██▒▀█▀ ██▒▒████▄    
\\▒███   ▓██  ▀█ ██▒▒██▒▒██░▄▄▄░▓██    ▓██░▒██  ▀█▄  
\\▒▓█  ▄ ▓██▒  ▐▌██▒░██░░▓█  ██▓▒██    ▒██ ░██▄▄▄▄██ 
\\░▒████▒▒██░   ▓██░░██░░▒▓███▀▒▒██▒   ░██▒ ▓█   ▓██▒
\\░░ ▒░ ░░ ▒░   ▒ ▒ ░▓   ░▒   ▒ ░ ▒░   ░  ░ ▒▒   ▓▒█░
\\ ░ ░  ░░ ░░   ░ ▒░ ▒ ░  ░   ░ ░  ░      ░  ▒   ▒▒ ░
\\   ░      ░   ░ ░  ▒ ░░ ░   ░ ░      ░     ░   ▒   
\\   ░  ░         ░  ░        ░        ░         ░  ░
\\=========================================<v0.0.0>=====
;

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    var stdout = &stdout_writer.interface;

    var stdin_buffer: [1096]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    var stdin = &stdin_reader.interface;

    const gpa = std.heap.page_allocator;

    try stdout.print("\x1b[2J\x1b[H\x1b[34m{s}\x1b[0m\n", .{TITLE_CARD});
    try stdout.flush();

    const operators = enigma.default_operators(gpa);
    var interpreter = try enigma.Interpreter.init(gpa);
    defer interpreter.deinit();

    while (true) {
        const input = try stdin.takeDelimiterExclusive('\n');
        if (std.mem.eql(u8, input, "end")) {
            break;         
        } else {
            var token_stream = try enigma.TokenStream.init(gpa, input, .{ .operators = operators });
            
        }
    }


    // const operators = try enigma.default_operators(gpa);    
    // var tokens = try enigma.TokenStream.init(gpa, "(2 + 7) * 8 / 4", .{ .operators = operators});
    // defer tokens.deinit(gpa);

    // std.debug.print("{f}\n", .{tokens});

    // var ast = try enigma.SyntaxTree.init(gpa, tokens);
    // std.debug.print("{f}\n", .{ast});

    // var interpreter = try enigma.Interpreter.init(gpa);
    // const result = try interpreter.run(&ast);

    // if (result) |res| {
    //     std.debug.print("Result: {f}\n", .{res});
    // }
}
