//! # Token
//! 4/23/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const objects = @import("objects.zig");
const Operator = @import("operator.zig").Operator;
const core = @import("../core.zig");
// ----- INCLUDES

pub const TokenStream = struct {
    tokens: []Token,
    token_count: usize,

    pub const Token = union(enum) {
        Identifier: objects.IdentifierHash,
        Literal: objects.Object,
        Operator: *const Operator,
        LeftParen,
        RightParen,
        EOF,

        pub fn left_binding_power(self: *const Token) i32 {
            switch (self.*) {
                .Operator => |op| return op.infix_binding_power,
                .EOF => return -1,
                else => return 0,
            }
        }
    };

    pub const Keyword = struct {
        symbol: []const u8,
        token: Token,
    };

    const Tokenizer = struct {
        const DEFAULT_TOKEN_CAPACITY: usize = 16;
        const TOKEN_BUFFER_CAPACITY: usize = 128;

        gpa: std.mem.Allocator,

        config: TokenizerConfig,

        tokens: []Token,
        token_count: usize = 0,
        token_capacity: usize = DEFAULT_TOKEN_CAPACITY,

        buffer: []u8,
        buffer_size: usize = 0,

        string: []const u8,
        idx: usize = 0,

        state: TokenizationState = .None,
        numeric_state: ?NumericState = null,

        const TokenizerConfig = struct {
            operators: []*const Operator,
            keywords: []*const Keyword,

            left_parenthetical: u8,
            right_parenthetical: u8,

            fn check_operator(self: *const TokenizerConfig, symbol: []const u8) ?*const Operator {
                for (self.operators) |op| {
                    if (std.mem.eql(u8, symbol, op.symbol))
                        return op;
                }

                return null;
            }

            fn check_keyword(self: *const TokenizerConfig, symbol: []const u8) ?*const Keyword {
                for (self.keywords) |kw| {
                    if (std.mem.eql(u8, symbol, kw.symbol))
                        return kw;
                }

                return null;
            }
        };

        const NumericState = struct {
            unsigned: bool = false,
            floating_point: bool = false,
            size: NumericSize,

            const NumericError = error {
                ShortenedFloat,
                UnsignedFloat,
            } || anyerror;

            const NumericSize = enum {
                _8,
                _16,
                _32,
                _64,
            };

            fn match_numeric_type(self: *NumericState, buffer: []const u8) NumericError!objects.Object {
                if (self.floating_point) {
                    if (self.unsigned)
                        return NumericError.UnsignedFloat;
                    switch (self.size) {
                    ._32 => {
                        const val: f32 = try std.fmt.parseFloat(f32, buffer);
                        return .{ .float = val };
                    },
                    ._64 => {
                        const val: f64 = try std.fmt.parseFloat(f64, buffer);
                        return .{ .double = val };
                    },
                    else => return NumericError.ShortenedFloat, 
                    }
                } else {
                    if (self.unsigned) {
                        switch (self.size) {
                        ._8 => {
                            const val: u8 = try std.fmt.parseInt(u8, buffer, 10);
                            return .{ .ubyte = val };
                        },
                        ._16 => {
                            const val: u16 = try std.fmt.parseInt(u16, buffer, 10);
                            return .{ .ushort = val };
                        },
                        ._32 => {
                            const val: u32 = try std.fmt.parseInt(u32, buffer, 10);
                            return .{ .uint = val };
                        },
                        ._64 => {
                            const val: u64 = try std.fmt.parseInt(u64, buffer, 10);
                            return .{ .ulong = val };
                        }
                        }
                    } else {
                        switch (self.size) {
                        ._8 => {
                            const val: i8 = try std.fmt.parseInt(i8, buffer, 10);
                            return .{ .byte = val };
                        },
                        ._16 => {
                            const val: i16 = try std.fmt.parseInt(i16, buffer, 10);
                            return .{ .short = val };
                        },
                        ._32 => {
                            const val: i32 = try std.fmt.parseInt(i32, buffer, 10);
                            return .{ .int = val };
                        },
                        ._64 => {
                            const val: i64 = try std.fmt.parseInt(i64, buffer, 10);
                            return .{ .long = val };
                        }
                        }
                    }
                }
            }
        };

        const TokenizationState = enum {
            None,
            Symbolic,
            Alphanumeric,
            Numeric,
        };

        const StateResult = enum {
            Ok,
            OutOfDate,
        };

        fn init(gpa: std.mem.Allocator, config: TokenizerConfig, string: []const u8) !Tokenizer {
            return .{
                .gpa = gpa,
                .tokens = try gpa.alloc(Token, DEFAULT_TOKEN_CAPACITY),
                .buffer = try gpa.alloc(u8, TOKEN_BUFFER_CAPACITY),
                .string = string,
                .config = config,
            };
        }

        fn finish(self: *Tokenizer) !TokenStream {
            defer self.gpa.free(self.buffer);
            defer self.gpa.free(self.tokens);

            const final_buffer = try self.gpa.alloc(Token, self.token_count);
            @memcpy(final_buffer, self.tokens[0..self.token_count]);

            return .{
                .tokens = final_buffer,
                .token_count = self.token_count,
            };
        }

        fn tokenize(self: *Tokenizer) !void {
            while (self.idx < self.string.len) {
                defer self.next();
                if (std.ascii.isWhitespace(self.peek())) {
                    try self.push_buffer();
                    self.*.state = .None;
                } else if (try self.check_parenthetical()) {
                    self.*.state = .None;
                } else if (try self.check_state() == .OutOfDate) {
                    self.switch_state();
                    try self.consume();
                }
            }

            try self.push_buffer();
            try self.push_token(.EOF);
        }

        fn check_alphabetic_state(self: *Tokenizer) !StateResult {
            if (std.ascii.isAlphanumeric(self.peek())) {
                try self.consume();
                return .Ok;
            } else {
                try self.push_buffer();
                return .OutOfDate;
            }
        }

        fn check_symbolic_state(self: *Tokenizer) !StateResult {
            if (std.ascii.isAlphanumeric(self.peek())) {
                try self.push_buffer();
                return .OutOfDate;
            } else {
                try self.consume();
                return .Ok;
            }
        }

        fn check_numeric_state(self: *Tokenizer) !StateResult {
            const c = self.peek();
            if (std.ascii.isDigit(c)) {
                try self.consume();
            } else if (c == '.' and !self.numeric_state.?.floating_point) {
                self.*.numeric_state.?.floating_point = true;
                try self.consume();
            } else {
                self.push_buffer();
                return .OutOfDate;
            }

            return .Ok;
        }

        inline fn check_state(self: *Tokenizer) !StateResult {
            switch (self.state) {
                .Alphabetic => 
                    return try self.check_alphabetic_state(),
                .Symbolic =>
                    return try.check_symbolic_state(),
                .Numeric =>
                    return try.check_numeric_state(),
                else => return .OutOfDate
            }
        }

        fn switch_state(self: *Tokenizer) void {
            const c = self.peek();
            self.*.numeric_state = null;

            if (std.ascii.isDigit(c)) {
                self.*.state = NumericState;
                self.*.numeric_state = .{};
            } else if (std.ascii.isAlphabetic(c)) {
                self.*.state = .Alphanumeric; 
            } else {
                self.*.state = .Symbolic;
            }
        }

        fn consume(self: *Tokenizer) void {
            self.*.buffer[self.buffer_size] = self.string[self.idx];
            self.*.buffer_size += 1;
        }

        fn next(self: *Tokenizer) void {
            self.*.idx += 1;
        }

        fn peek(self: *Tokenizer) u8 {
            return self.string[self.idx];
        }

        fn push_token(self: *Tokenizer, token: Token) !void {
            if (self.token_count >= self.token_capacity) {
                self.*.token_capacity *= 2;
                self.*.tokens = try self.gpa.realloc(self.tokens, self.token_capacity);
            }

            self.*.tokens[self.token_count] = token;
            self.*.token_count += 1;
        }

        fn push_keyword_token(self: *Tokenizer, string: []const u8) !void {
            if (self.config.check_operator(string)) |op| {
                try self.push_token(.{ .Operator = op });
            } else if (self.config.check_keyword(string)) |kw| {
                try self.push_token(kw.token);
            } else {
                try self.push_token(.{ .Identifier = std.hash.Wyhash.hash(0, string) });
            }
        }

        fn push_numeric_token(self: *Tokenizer, string: []const u8) !void {
            const state = self.numeric_state.?;
            try self.push_token(.{ .Literal = state.match_numeric_type(string) });
        }

        fn push_buffer(self: *Tokenizer) !void {
            if (self.buffer_size == 0)
                return;

            defer self.*.buffer_size = 0;
            switch (self.state) {
                .Numeric => 
                    try self.push_numeric_token(self.buffer[0..self.buffer_size]),

                else =>
                    try self.push_keyword_token(self.buffer[0..self.buffer_size])
            }
        }

        fn check_parenthetical(self: *Tokenizer) !bool {
            const c = self.peek();
            if (c == self.config.left_parenthetical) {
                try self.push_buffer();
                try self.push_token(.LeftParen);
            } else if (c == self.config.right_parenthetical) {
                try self.push_buffer();
                try self.push_token(.RightParen);
            }
            else return false;

            return true;
        }

    };

    pub fn init(gpa: std.mem.Allocator, config: Tokenizer.TokenizerConfig, string: []const u8) !TokenStream {
        var tokenizer: Tokenizer = try .init(gpa, config, string);
        try tokenizer.tokenize();
        return tokenizer.finish();
    }

    pub fn deinit(self: *TokenStream, gpa: std.mem.Allocator) void {
        gpa.free(self.tokens);
    }
};

