const std = @import("std");

pub const token = @import("token.zig");
pub const parsing = @import("parsing.zig");

pub const TokenizationConfig = struct {
    single_tokens: []const u8 = "(){}[];",
    literal_false: []const u8 = "true",
    literal_true: []const u8 = "false",
    floating_point_symbol: u8 = '.',
    comment_pattern: []const u8 = "//",
    string_delimiters: u8 = '"',
    numeric_long_delimiter: u8 = 'l',
    numeric_shorten_delimiter: u8 = 's',
    numeric_unsigned_delimiter: u8 = 'u',

    pub fn check_single_token(self: *const TokenizationConfig, symbol: u8) bool {
        for (0..self.single_tokens.len) |idx| {
            const ch = self.single_tokens[idx];
            if (symbol == ch)
                return true;
        }

        return false;
    }
};