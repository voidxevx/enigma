const std = @import("std");

pub const TokenizationError = error {
    MultipleDecimalPointsInFloat,
};