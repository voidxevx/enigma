//! # Enigma
//! 4/18/2026 - Nyx

// INCLUDES -----
const std = @import("std");
// ----- INCLUDES

// MODULES -----
// ----- MODULES

// LEXICS -----
pub const Operator = struct {
    symbol: u8,
    infix_binding_power: i32,

    pub fn format(self: *const Operator, writer: *std.io.Writer) std.Io.Writer.Error!void {
        try writer.print("\x1b[4m{c}\x1b[0m", .{self.symbol});
    }
};

pub const Token = union(enum) {
    Identifier: u8,
    Int: u8,
    Operator: *const Operator,

    pub fn format(self: *const Token, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self.*) {
            .Identifier => |id| try writer.print("\x1b[4;33m{c}\x1b[0m", .{id}),
            .Int => |i| try writer.print("{d}", .{i}),
            .Operator => |op| try writer.print("{f}", .{op}),
        }
    }

    pub fn get_infix_binding_power(self: *const Token) i32 {
        switch (self.*) {
            .Operator => |op| return op.infix_binding_power,
            else => return 0, 
        }
    }
};



pub const TokenStream = struct {
    tokens: []Token,
    token_count: usize,
    config: TokenConfig,

    pub const TokenConfig = struct {
        operators: std.ArrayList(Operator),

        fn check_operator(self: *const TokenConfig, symbol: u8) ?*const Operator {
            for (self.operators.items) |*op| {
                if (op.symbol == symbol)
                    return op;
            }

            return null;
        }
    };

    pub fn init(gpa: std.mem.Allocator, config: TokenConfig, str: []const u8) !TokenStream {
        // Initially allocates a buffer equals to the count of characters.
        var buffer = try gpa.alloc(Token, str.len);
        var token_count: usize = 0;

        for (str) |ch| {
            if (std.ascii.isWhitespace(ch))
                continue;
            
            if (config.check_operator(ch)) |op| {
                buffer[token_count] = .{ .Operator = op };
            } else if (std.ascii.isDigit(ch)) {
                buffer[token_count] = .{ .Int = try std.fmt.charToDigit(ch, 10) };
            } else {
                buffer[token_count] = .{ .Identifier = ch };
            }
            token_count += 1;
        }

        if (token_count != str.len) {
            const new_buffer = try gpa.alloc(Token, token_count);
            @memmove(new_buffer, buffer[0..token_count]);
            gpa.free(buffer);
            buffer = new_buffer;
        }

        return .{
            .token_count = token_count,
            .tokens = buffer,
            .config = config,
        };
    }

    pub fn deinit(self: TokenStream, gpa: std.mem.Allocator) void {
        gpa.free(self.tokens);
    }

    pub fn format(self: *const TokenStream, writer: *std.io.Writer) std.Io.Writer.Error!void {
        for (self.tokens) |token|
            try writer.print("{f} ", .{token});
    }

};
// ----- LEXICS



// PARSING -----



// ----- PARSING