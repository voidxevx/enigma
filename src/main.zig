const std = @import("std");
const enigma = @import("enigma");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    var stdout = &stdout_writer.interface;

    const gpa = std.heap.page_allocator;

    const package = 
        try enigma.tokenization.parsing.tokenize_string(
            gpa, 
            "Test|ng 1ul, 2.0, 3 -- \"Yippie yay\"",
            null
        );

    try package.format(stdout);
    try stdout.flush();
}