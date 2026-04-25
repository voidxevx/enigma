//! # Enigma (zig root)
//! 4/22/2026 - Nyx

// INCLUDES -----
const std = @import("std");
// ----- INCLUDES

// MODULES -----
const interpreter = @import("interpreter/mod.zig");
// ----- MODULES

// COMPTIME BINDINGS
comptime {
    _ = interpreter.mem.stack.test_stack;

}
