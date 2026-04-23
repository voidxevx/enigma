//! # Enigma (zig root)
//! 4/22/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const interpreter = @import("interpreter/interpreter.zig");
// ----- INCLUDES

// COMPTIME BINDINGS
comptime {
    // Interpreter ffi bindings -----
    _ = interpreter.new_interpreter;
    _ = interpreter.destroy_interpreter;
    _ = interpreter.push_to_interpreter;
    _ = interpreter.pop_from_interpreter;
    _ = interpreter.is_interpreter_stack_empty;
    _ = interpreter.flush_interpreter;
    _ = interpreter.interpreter_allocate;
    _ = interpreter.interpreter_free;
    _ = interpreter.interpreter_get;
    _ = interpreter.interpreter_get_mut;
    // ----- Interpreter ffi bindings
}
