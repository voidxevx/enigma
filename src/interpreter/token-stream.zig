//! # Token Stream
//! 4/23/2026 - Nyx
//! 
//! Token Streams hold a list of tokens that can be used and iterated over later
//! during parsing. This is an implementation of a Deterministic Finite Automata lexics
//! algorithm. 

// INCLUDES -----
const std = @import("std");
const objects = @import("objects.zig");
const Operator = @import("operator.zig").Operator;
const core = @import("../core.zig");
// ----- INCLUDES

/// Token Stream
/// 
/// Stream of tokens that can be iterated an analyzed later.
/// Automatically handles all the tokenization functionality.
///
/// # Example
/// 
/// ```zig
/// const TokenStream = @import("token-stream.zig");
/// const std = @import("std");
/// 
/// const ts: TokenStream = try .init(std.heap.page_allocator, .{}, "Testing, 1, 2, 3");
/// ``` 
pub const TokenStream = struct {

    tokens: []Token,
    token_count: usize,

    /// Token
    /// 
    /// A Single token representing a grouped keyword, literal, or identifier.
    pub const Token = union(enum) {

        /// An hashed identifier
        Identifier: objects.IdentifierHash,

        /// Static object literal
        Literal: objects.Object,

        /// Operator reference
        Operator: *const Operator,

        /// Opening left parenthetic.
        LeftParen,

        /// Closing right parenthetic.
        RightParen,

        /// End of the token stream.
        EOF,

        /// Gets the left binding power for parsing.
        /// 
        /// Operators use their set binding power. EOF is always -1, any others are 0.
        pub fn left_binding_power(self: *const Token) i32 {
            switch (self.*) {
                .Operator => |op| return op.infix_binding_power,
                .EOF => return -1,
                else => return 0,
            }
        }
    };

    /// An individual keyword that will be matched to a specified token.
    pub const Keyword = struct {
        symbol: []const u8,
        token: Token,
    };

    /// Tokenizer
    /// 
    /// Converts (tokenizes) a string into a stream of tokens.
    /// This implements a deterministic finite automata (dfa) algorithm.
    /// A dfa treats the parsing process as a state machine interpreting each character
    /// of the string as a potential change in state. Each state of the dfa has a 
    /// specific set of rules that determine how it is transformed to another state.
    /// Each state once finished will result in a token being pushed into the stream.
    /// 
    /// This holds additional values required during tokenization. Once the tokenizer 
    /// finishes it will compact the token stream buffer as well as deallocate any 
    /// extra resources that were stored during the process.
    const Tokenizer = struct {
        /// The default capacity for the token stream buffer
        const DEFAULT_TOKEN_CAPACITY: usize = 16;
        /// The capacity of the buffer. This determines the longest identifier that can be stored.
        const TOKEN_BUFFER_CAPACITY: usize = 128;

        /// General purpose allocator.
        gpa: std.mem.Allocator,

        /// The configuration for the tokens
        config: TokenizerConfig,

        /// The token stream buffer
        /// 
        /// This during the tokenization process has an extended buffer
        /// that will grow when needed. Once the tokenizer is finished 
        /// the buffer will be compacted.
        tokens: []Token,
        token_count: usize = 0,
        token_capacity: usize = DEFAULT_TOKEN_CAPACITY,

        /// The buffer for the currently being parsed token.
        /// This is a statically sized buffer that wont be deallocated
        /// or changed until the tokenizer finishes freeing the buffer.
        buffer: []u8,
        buffer_size: usize = 0,

        /// The string being parsed
        string: []const u8,
        /// The current index within the string
        idx: usize = 0,

        /// The current state of the dfa
        state: TokenizationState = .None,
        /// The state of a currently parsed numeric literal
        numeric_state: ?NumericState = null,

        /// Configuration for the tokenizer.
        /// 
        /// Stores the specific keyword tokens that are matched and the operators that
        /// are matched.
        const TokenizerConfig = struct {
            operators: []*const Operator,
            keywords: []*const Keyword,

            /// The character for a left parenthetical: '('
            left_parenthetical: u8 = '(',
            /// The character for a right parenthetical: '('
            right_parenthetical: u8 = ')',

            /// Checks if an symbol matches an operator and returns what operator it matches.
            fn check_operator(self: *const TokenizerConfig, symbol: []const u8) ?*const Operator {
                for (self.operators) |op| {
                    if (std.mem.eql(u8, symbol, op.symbol))
                        return op;
                }

                return null;
            }

            /// Checks if a symbol matches a keyword and returns the token that the keyword matches.
            fn check_keyword(self: *const TokenizerConfig, symbol: []const u8) ?*const Keyword {
                for (self.keywords) |kw| {
                    if (std.mem.eql(u8, symbol, kw.symbol))
                        return kw;
                }

                return null;
            }
        };

        /// The state of a currently being parsed numeric literal.
        const NumericState = struct {
            /// If the number is unsigned
            unsigned: bool = false,

            /// If the number is floating point (float/double)
            floating_point: bool = false,

            /// The bit size of the number.
            size: NumericSize = ._32,

            /// Possible errors of while creating a numeric literal.
            const NumericError = error {
                /// A float is smaller than 32 or 64 bits
                ShortenedFloat,
                /// A float was marked as unsigned
                UnsignedFloat,
            } || anyerror;

            /// The bit size of a number.
            /// 
            /// Floating point numbers must be 32 or 64 bits.
            const NumericSize = enum {
                _8,
                _16,
                _32,
                _64,
            };

            /// Matches the current state creating a object literal.
            fn match_numeric_type(self: *const NumericState, buffer: []const u8) NumericError!objects.Object {
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

        /// The state of the tokenizer.
        const TokenizationState = enum {
            /// No State -> should immediately switch to a new state. 
            None,
            /// Symbol patterns and operators.
            Symbolic,
            /// Keywords made up of alphanumeric characters.
            Alphabetic,
            /// Static literal numbers.
            Numeric,
        };

        const StateResult = enum {
            Ok,
            /// The state is out of date and should be switched
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

        /// Finalizes the tokenizer freeing and allocated space and creating a token stream.
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

        /// Tokenizes the string.
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
                    self.consume();
                }
            }

            try self.push_buffer();
            try self.push_token(.EOF);
        }

        /// Checks the status of the alphabetic state
        fn check_alphabetic_state(self: *Tokenizer) !StateResult {
            if (std.ascii.isAlphanumeric(self.peek())) {
                self.consume();
                return .Ok;
            } else {
                try self.push_buffer();
                return .OutOfDate;
            }
        }

        /// Checks the status of the symbolic state
        fn check_symbolic_state(self: *Tokenizer) !StateResult {
            if (std.ascii.isAlphanumeric(self.peek())) {
                try self.push_buffer();
                return .OutOfDate;
            } else {
                self.consume();
                return .Ok;
            }
        }

        /// Checks the status of the numeric state
        fn check_numeric_state(self: *Tokenizer) !StateResult {
            const c = self.peek();
            if (std.ascii.isDigit(c)) {
                self.consume();
            } else if (c == '.' and !self.numeric_state.?.floating_point) {
                self.*.numeric_state.?.floating_point = true;
                self.consume();
            } else {
                try self.push_buffer();
                return .OutOfDate;
            }

            return .Ok;
        }

        /// Checks the status of the current state.
        inline fn check_state(self: *Tokenizer) !StateResult {
            switch (self.state) {
                .Alphabetic => 
                    return try self.check_alphabetic_state(),
                .Symbolic =>
                    return try self.check_symbolic_state(),
                .Numeric =>
                    return try self.check_numeric_state(),
                else => return .OutOfDate
            }
        }

        /// Switches the state depending on the current character.
        fn switch_state(self: *Tokenizer) void {
            const c = self.peek();
            self.*.numeric_state = null;

            if (std.ascii.isDigit(c)) {
                self.*.state = .Numeric;
                self.*.numeric_state = .{};
            } else if (std.ascii.isAlphabetic(c)) {
                self.*.state = .Alphabetic; 
            } else {
                self.*.state = .Symbolic;
            }
        }

        /// Consumes the current character adding it to the buffer.
        fn consume(self: *Tokenizer) void {
            self.*.buffer[self.buffer_size] = self.string[self.idx];
            self.*.buffer_size += 1;
        }

        /// Precedes to the next character in the string
        fn next(self: *Tokenizer) void {
            self.*.idx += 1;
        }

        /// Get the current character
        fn peek(self: *Tokenizer) u8 {
            return self.string[self.idx];
        }

        /// Pushes a token to the token stream buffer
        fn push_token(self: *Tokenizer, token: Token) !void {
            if (self.token_count >= self.token_capacity) {
                self.*.token_capacity *= 2;
                self.*.tokens = try self.gpa.realloc(self.tokens, self.token_capacity);
            }

            self.*.tokens[self.token_count] = token;
            self.*.token_count += 1;
        }

        /// Pushes an operator, keyword, or identifier token
        fn push_keyword_token(self: *Tokenizer, string: []const u8) !void {
            if (self.config.check_operator(string)) |op| {
                try self.push_token(.{ .Operator = op });
            } else if (self.config.check_keyword(string)) |kw| {
                try self.push_token(kw.token);
            } else {
                try self.push_token(.{ .Identifier = std.hash.Wyhash.hash(0, string) });
            }
        }

        /// Pushes a numeric literal token
        fn push_numeric_token(self: *Tokenizer, string: []const u8) !void {
            const state = self.numeric_state.?;
            try self.push_token(.{ .Literal = try state.match_numeric_type(string) });
        }

        /// Pushes the current buffer as a token
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

        /// Checks the current character for parentheses
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