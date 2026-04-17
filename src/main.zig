const std = @import("std");
const enigma = @import("enigma");

pub fn main() !void {
    const package = 
        try enigma.tokenization.parsing.tokenize_string(
            std.heap.page_allocator, 
            "Testing 1, 2, 3", 
            null
        );
    std.debug.print("{f}", .{package});
}