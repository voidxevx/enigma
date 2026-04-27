//! # Enigma (zig root)
//! 4/22/2026 - Nyx

// INCLUDES -----
const std = @import("std");
// ----- INCLUDES

// MODULES -----
const interpreter = @import("interpreter/mod.zig");
const core = @import("core.zig");
// ----- MODULES

// COMPTIME BINDINGS
comptime {
    _ = interpreter.vm.test_vm;
    _ = root_test;
}

const TokenStream = interpreter.oasm.tokenizer.TokenStream;

export fn root_test() void {
    const file = std.fs.cwd().openFile("content/tests/asm/test.oasm", .{}) catch @panic("failed to open file");
    defer file.close();

    const str = file.readToEndAlloc(core.allocator, std.math.maxInt(usize)) catch @panic("failed to read file");
    defer core.allocator.free(str);

    var ts = TokenStream.init(core.allocator, str) catch @panic("Failed to tokenize");
    defer ts.deinit(core.allocator);
    std.debug.print("{f}\n", .{ts});
}
