//! # Operator
//! 4/23/2026

pub const Operator = struct {
    symbol: []const u8,
    prefix_binding_power: ?i32 = null,
    infix_binding_power: ?i32 = null,
};