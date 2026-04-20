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

    const operators = try enigma.default_operators(gpa);
    var interpreter = try enigma.Interpreter.init(gpa);
    defer interpreter.deinit();

    while (true) {
        try stdout.print(">> ", .{});
        try stdout.flush();

        const input = try stdin.takeDelimiterExclusive('\n');
        stdin.toss(1); 
       
        var token_stream = try enigma.TokenStream.init(gpa, input, .{ .operators = operators });

        if (token_stream.token_count == 1)
            break;

        defer token_stream.deinit(gpa);
        var ast = try enigma.SyntaxTree.init(gpa, token_stream);
        defer ast.deinit(gpa);

        const result = try interpreter.run(&ast);
        if (result) |res| {
            try stdout.print("= {f}\n", .{res});
        }

        try stdout.flush();
    }

}
