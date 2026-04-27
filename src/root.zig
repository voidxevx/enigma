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
    const str = "mov r1 #0";

    var ts = TokenStream.init(core.allocator, str) catch @panic("Failed to tokenize");
    defer ts.deinit(core.allocator);
    std.debug.print("{f}\n", .{ts});
}
