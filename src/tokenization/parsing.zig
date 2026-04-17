const std = @import("std");
const token = @import("token.zig");

// Deterministic finite automata

const TokenizationState = enum {
    None,
    Alphabetic,
    Numeric,
    Symbolic,
    String,
};

fn switch_tokenization_state(allocator: std.mem.Allocator, current_char: u8, state: *TokenizationState, buffer: *std.ArrayList(u8)) !void {
    if (current_char == '"') {
        state.* = .String;
    } else if (std.ascii.isAlphabetic(current_char)) {
        state.* = .Alphabetic;
    } else if (std.ascii.isDigit(current_char)) {
        state.* = .Numeric;
    } else {
        state.* = .Symbolic;
    }

    if (state.* != .String) {
        try buffer.append(allocator, current_char);
    }
}

fn push_token(allocator: std.mem.Allocator, package: *token.TokenPackage, buffer: *std.ArrayList(u8), line: ?usize, column_start: usize, column_end: usize) !void {
    if (buffer.items.len == 0)
        return;
    
    defer buffer.clearRetainingCapacity();

    const token_type: token.TokenType = 
        if (std.mem.eql(u8, buffer.items, "true"))
            token.TokenType {
                .literal = .{ .bool = true }
            }
        else if (std.mem.eql(u8, buffer.items, "false"))
            token.TokenType {
                .literal = .{ .bool = false }
            }
        else buffer_copy: {
            const copy = try buffer.clone(allocator);
            break :buffer_copy token.TokenType {
                .identifier = copy.items
            };
        };

    try package.add_token(.{
        .token_type = token_type,
        .line = line,
        .column_start =  column_start,
        .column_end = column_end,
    });
}


pub fn tokenize_string(allocator: std.mem.Allocator, string: []const u8, line: ?usize) !token.TokenPackage {
    var package = try token.TokenPackage.init(null, allocator);

    var state: TokenizationState = .None;

    var buffer = try std.ArrayList(u8).initCapacity(allocator, 128);
    defer buffer.deinit(allocator);

    var idx: usize = 0;
    tokenization_loop: while (idx < string.len) {
        const current = string[idx];

        if (std.ascii.isWhitespace(current)) {
            try push_token(allocator, &package, &buffer, line, 0, 0);
            idx += 1;
            continue: tokenization_loop;
        }

        switch (state) {
            .None => 
                try switch_tokenization_state(allocator, current, &state, &buffer),

            else => {
                try buffer.append(allocator, current);
            }
        }        

        idx += 1;
    }

    try push_token(allocator, &package, &buffer, line, 0, 0);

    return package;
}