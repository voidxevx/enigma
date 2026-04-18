//! # Errors
//! 4/17/2026 - Nyx

// INCLUDES
const std = @import("std");

/// Possible errors during tokenization.
/// 
/// As of right now there is only one error caused by multiple floating 
/// points found within a numeric literal.
pub const TokenizationError = error {
    /// Multiple floating point symbols were encountered while parsing a numeric literal.
    MultipleDecimalPointsInFloat,
};