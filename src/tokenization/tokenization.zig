//! # Tokenization
//! 4/17/2026 - Nyx
//! 
//! Tokenization splits a string of text into its primitive tokens.
//! Splitting text into tokens makes analyzing and parsing the text mush simpler.
//! In most cases you would have a multitude of possible tokens but in the case for 
//! Enigma tokens only fall into two categories: Identifiers and Literals. Literals are any 
//! constant type such as an integer, string, float, etc. Identifiers are just about anything else. 
//! Identifiers are split by symbolic and alphabetic characters.

// INCLUDES
const std = @import("std");

// MODULES -----
pub const token = @import("token.zig");
pub const parsing = @import("parsing.zig");
// ----- MODULES


/// Tokenization Config
/// 
/// set of options for tokenizing a string.
pub const TokenizationConfig = struct {

    /// Singled out tokens. 
    /// 
    /// Every token in this array, when encountered will be treated as a single token 
    /// whether or not it is adjacent to another token of the same state.
    single_tokens: []const u8 = "(){}[];",

    /// The identifier that is matched to the literal `true` value.
    literal_false: []const u8 = "true",

    /// The identifier that is matched to literal `false` value.
    literal_true: []const u8 = "false",

    /// Marks the start of floating point number.
    floating_point_symbol: u8 = '.',

    /// Pattern that will automatically exit a line allowing for the rest of the line to be comments
    comment_pattern: []const u8 = "//",

    /// Character that marks the start and end of a string literal.
    string_delimiters: u8 = '"',

    /// Character that changes a numeric literal to be 64 bits.
    numeric_long_delimiter: u8 = 'l',

    /// Character that shortens a numeric literal from 32bits -> 16bits -> 8bits.
    numeric_shorten_delimiter: u8 = 's',

    /// Character that marks a numeric literal as unsigned.
    numeric_unsigned_delimiter: u8 = 'u',

    /// Checks if a character is contained in the `single_tokens` list.
    pub fn check_single_token(self: *const TokenizationConfig, symbol: u8) bool {
        for (0..self.single_tokens.len) |idx| {
            const ch = self.single_tokens[idx];
            if (symbol == ch)
                return true;
        }

        return false;
    }
};