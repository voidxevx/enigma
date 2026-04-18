//! # Operator
//! 4/18/2026 - Nyx

pub const Operator = struct {
    symbol: []const u8,
    prefix_binding_power: ?usize = null,
    suffix_binding_power: ?usize = null,
    infix_binding_power: ?usize = null,
};