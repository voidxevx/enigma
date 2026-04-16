const std = @import("std");
const enigma = @import("enigma");

pub fn main() !void {
    const token = enigma.token.Token { 
        .token_type = enigma.token.TokenType{
            .identifier = "Hello"
        },
        .line = null,
        .column = null,
    };

    _ = token;
}