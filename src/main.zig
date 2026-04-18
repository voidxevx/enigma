const std = @import("std");
const enigma = @import("enigma");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    var stdout = &stdout_writer.interface;

    const gpa = std.heap.page_allocator;

    const package = 
        try enigma
        .tokenization
        .parsing
        .tokenize_file(
            gpa, 
            "tests/main.eng",
            &.{}
        );
    
    try stdout.print("{f}", .{package});
    try stdout.flush();

    var node = enigma.lexing.node.NullNode {};

    const inode = node.interface();
    try stdout.print("{f}", .{inode});
    try stdout.flush();

}