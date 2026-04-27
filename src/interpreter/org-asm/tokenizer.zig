//! Org-Asm Tokenizer
//! 4/26/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const tokens = @import("tokens.zig");
const Token = tokens.Token;
const RegisterData = tokens.RegisterData;
const proc = @import("procedure.zig");
const Procedure = proc.Procedure;
const Tag = proc.Tag;
// ----- INCLUDES

pub const TokenStream = struct {
    tokens: []Token,

    const Tokenizer = struct {
        const DEFAULT_TOKEN_CAPACITY: usize = 16;
        const BUFFER_CAPACITY: usize = 128;

        gpa: std.mem.Allocator,

        string: []const u8,
        idx: usize = 0,

        tokens: []Token,
        token_count: usize = 0,
        token_capacity: usize = DEFAULT_TOKEN_CAPACITY,

        buffer: []u8,
        buffer_size: usize = 0,

        state: union(enum(u3)) {
            /// needs to switch next
            bad,

            /// Identifiers, Procedures, Tags
            none,
            numeric: NumericState,
            string,
            register: RegisterData,
        } = .bad,

        const StateResult = enum {
            Ok,
            OutOfDate,
        };

        const NumericState = struct {
            format: Format = .Decimal,
            size: Size = .default,
            floating_point: bool = false,
            unsigned: bool = false,
            expecting: enum {
                format,
                values,
                size,
            } = .format,

            const Format = enum {
                Decimal, // #...
                Hex, // #h...
                Binary, // #b...
            };
            const Size = enum {
                byte, // 1byte
                short, // 2bytes
                default, // 4bytes
                long, // 8bytes
                longlong, // 16bytes
            };

            fn shorten(self: *NumericState) !void {
                switch (self.size) {
                    .short => self.*.size = .byte,
                    .default => self.*.size = .short,
                    else => return ParseError.CannotShorten,
                }
            }

            fn elongate(self: *NumericState) !void {
                switch (self.size) {
                    .default => self.*.size = .long,
                    .long => self.*.size = .longlong,
                    else => return ParseError.CannotElongate,
                }
            }

            /// Parses a int given a specific format
            fn parse_format(comptime T: type, buffer: []const u8, _format: Format) !T {
                return try std.fmt.parseInt(T, buffer, switch (_format) {
                    .Decimal => 10,
                    .Hex => 16,
                    .Binary => 2,
                });
            }

            /// Converts a type into a copy of its bytes to resulting buffer must be freed (tokens should handle this)
            fn make_bytes(comptime T: type, val: T, gpa: std.mem.Allocator) ![]u8 {
                switch (@typeInfo(T)) {
                    .int => {
                        const buf: []u8 = try gpa.alloc(u8, @sizeOf(T));
                        var capture: [@sizeOf(T)]u8 = undefined;
                        std.mem.writeInt(T, &capture, val, .little);
                        @memmove(buf, &capture);
                        return buf;
                    },
                    .float => {
                        const buf: []u8 = try gpa.alloc(u8, @sizeOf(T));
                        var capture: [@sizeOf(T)]u8 = undefined;
                        const Tc: type = if (@sizeOf(T) == 16) i128 else if (@sizeOf(T) == 8) i64 else i32;
                        const as_int: Tc = @bitCast(val);
                        std.mem.writeInt(Tc, &capture, as_int, .little);
                        @memmove(buf, &capture);
                        return buf;
                    },
                    else => {},
                }
            }

            const ParseError = error{
                UnsignedFloat,
                CannotShorten,
                CannotElongate,
            };

            // outputs bytes
            fn parse(self: NumericState, gpa: std.mem.Allocator, buffer: []const u8) ![]u8 {
                switch (self.size) {
                    .byte => {
                        if (self.unsigned) {
                            const val = try parse_format(u8, buffer, self.format);
                            return try make_bytes(u8, val, gpa);
                        } else {
                            const val = try parse_format(i8, buffer, self.format);
                            return try make_bytes(i8, val, gpa);
                        }
                    },
                    .short => {
                        if (self.unsigned) {
                            const val = try parse_format(u16, buffer, self.format);
                            return try make_bytes(u16, val, gpa);
                        } else {
                            const val = try parse_format(i16, buffer, self.format);
                            return try make_bytes(i16, val, gpa);
                        }
                    },
                    .default => {
                        if (self.unsigned) {
                            if (self.floating_point)
                                return ParseError.UnsignedFloat;
                            const val = try parse_format(u32, buffer, self.format);
                            return try make_bytes(u32, val, gpa);
                        } else {
                            if (self.floating_point) {
                                const val = try std.fmt.parseFloat(f32, buffer);
                                return try make_bytes(f32, val, gpa);
                            } else {
                                const val = try parse_format(i32, buffer, self.format);
                                return try make_bytes(i32, val, gpa);
                            }
                        }
                    },
                    .long => {
                        if (self.unsigned) {
                            if (self.floating_point)
                                return ParseError.UnsignedFloat;
                            const val = try parse_format(u64, buffer, self.format);
                            return try make_bytes(u64, val, gpa);
                        } else {
                            if (self.floating_point) {
                                const val = try std.fmt.parseFloat(f64, buffer);
                                return try make_bytes(f64, val, gpa);
                            } else {
                                const val = try parse_format(i64, buffer, self.format);
                                return try make_bytes(i64, val, gpa);
                            }
                        }
                    },
                    .longlong => {
                        if (self.unsigned) {
                            if (self.floating_point)
                                return ParseError.UnsignedFloat;
                            const val = try parse_format(u128, buffer, self.format);
                            return try make_bytes(u128, val, gpa);
                        } else {
                            if (self.floating_point) {
                                const val = try std.fmt.parseFloat(f128, buffer);
                                return try make_bytes(f128, val, gpa);
                            } else {
                                const val = try parse_format(i128, buffer, self.format);
                                return try make_bytes(i128, val, gpa);
                            }
                        }
                    },
                }
            }
        };

        const Error = error{
            InvalidDigit,
            InvalidRegister,
        };

        fn init(gpa: std.mem.Allocator, string: []const u8) !Tokenizer {
            return .{
                .gpa = gpa,
                .string = string,
                .tokens = try gpa.alloc(Token, DEFAULT_TOKEN_CAPACITY),
                .buffer = try gpa.alloc(u8, BUFFER_CAPACITY),
            };
        }

        fn finish(self: *Tokenizer) !TokenStream {
            self.gpa.free(self.buffer);

            const finalized_buffer: []Token = try self.gpa.realloc(self.tokens, self.token_count);

            return .{
                .tokens = finalized_buffer,
            };
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

        fn switch_state(self: *Tokenizer) void {
            const current = self.peek();
            if (std.ascii.isWhitespace(current)) {
                self.*.state = .bad;
                return;
            }

            if (current == '"') {
                self.*.state = .string;
            } else if (current == '#') {
                self.*.state = .{ .numeric = .{} };
            } else if (current == '%') {
                self.*.state = .{ .register = .{} };
            } else {
                self.*.state = .none;
                self.consume();
            }
        }

        fn push_token(self: *Tokenizer, token: Token) !void {
            if (self.token_count >= self.token_capacity) {
                self.*.token_capacity *= 2;
                self.*.tokens = try self.gpa.realloc(self.tokens, self.token_capacity);
            }

            self.*.tokens[self.token_count] = token;
            self.*.token_count += 1;
        }

        fn push_standard_token(self: *Tokenizer, buffer: []const u8) !void {
            const as_lower = try std.ascii.allocLowerString(self.gpa, buffer);
            defer self.gpa.free(as_lower);

            const token: ?Token =
                select_token: {
                    if (std.mem.eql(u8, as_lower, "mov")) {
                        break :select_token .{ .Procedure = .MOV };
                    } else if (std.mem.eql(u8, as_lower, "push")) {
                        break :select_token .{ .Procedure = .PUSH };
                    } else if (std.mem.eql(u8, as_lower, "pop")) {
                        break :select_token .{ .Procedure = .POP };
                    } else if (std.mem.eql(u8, as_lower, "prog")) {
                        break :select_token .{ .Tag = .PROG };
                    } else if (std.mem.eql(u8, as_lower, "proc")) {
                        break :select_token .{ .Tag = .PROC };
                    } else {
                        break :select_token null;
                    }
                };

            if (token) |t| {
                try self.push_token(t);
            } else {
                const hash: u64 = std.hash.Wyhash.hash(0, buffer);
                try self.push_token(.{ .Identifier = hash });
            }
        }

        fn push_register_token(self: *Tokenizer) !void {
            if (!self.state.register.is_valid())
                return Error.InvalidRegister;
            try self.push_token(.{ .Register = self.state.register });
        }

        fn push_string_token(self: *Tokenizer, buffer: []const u8) !void {
            const buf = try self.gpa.alloc(u8, buffer.len);
            @memcpy(buf, buffer);
            try self.push_token(.{ .Data = buf });
        }

        fn push_numeric_token(self: *Tokenizer, buffer: []const u8) !void {
            switch (self.state) {
                .numeric => |num_state| {
                    const bytes: []u8 = try num_state.parse(self.gpa, buffer);
                    try self.push_token(.{ .Data = bytes });
                },
                else => unreachable,
            }
        }

        fn push_buffer(self: *Tokenizer) !void {
            if (self.buffer_size == 0)
                return;

            const buf: []const u8 = self.buffer[0..self.buffer_size];
            switch (self.state) {
                .none => try self.push_standard_token(buf),
                .numeric => try self.push_numeric_token(buf),
                .string => try self.push_string_token(buf),
                .register => try self.push_register_token(),
                .bad => unreachable,
            }

            self.*.buffer_size = 0;
        }

        fn check_standard_state(self: *Tokenizer) !StateResult {
            if (std.ascii.isWhitespace(self.peek())) {
                try self.push_buffer();
                self.*.state = .bad;
                return .OutOfDate;
            } else {
                self.consume();
                return .Ok;
            }
        }

        fn check_register_state(self: *Tokenizer) !StateResult {
            const current = self.peek();
            if (std.ascii.isDigit(current)) {
                self.*.state.register.id = try std.fmt.charToDigit(current, 10);
                try self.push_register_token();
                self.next();
                return .OutOfDate;
            } else {
                switch (current) {
                    's' => self.*.state.register.size = .small,
                    'l' => self.*.state.register.size = .large,
                    else => {
                        return Error.InvalidRegister;
                    }
                }
            return .Ok;
            }
        }

        fn check_string_state(self: *Tokenizer) !StateResult {
            if (self.peek() == '"') {
                try self.push_buffer();
                self.next();
                return .OutOfDate;
            } else {
                self.consume();
                return .Ok;
            }
        }

        fn check_numeric_state(self: *Tokenizer) !StateResult {
            const current = self.peek();
            if (std.ascii.isWhitespace(current)) {}
            const num_state = &self.*.state.numeric;
            switch (num_state.expecting) {
                .format => {
                    switch (current) {
                        'h' => num_state.*.format = .Hex,
                        'b' => num_state.*.format = .Binary,
                        else => {
                            if (std.ascii.isDigit(current) or current == '-') {
                                self.consume();
                            } else return Error.InvalidDigit;
                        },
                    }
                    num_state.*.expecting = .values;
                },
                .values => {
                    switch (num_state.format) {
                        .Decimal => {
                            if (std.ascii.isDigit(current) or current == '-') {
                                self.consume();
                            } else if (current == '.' and !num_state.floating_point) {
                                num_state.*.floating_point = true;
                                self.consume();
                            } else {
                                num_state.*.expecting = .size;
                                return self.check_numeric_state();
                            }
                        },
                        .Hex => {
                            if (std.ascii.isHex(current) or current == '-') {
                                self.consume();
                            } else {
                                num_state.*.expecting = .size;
                                return self.check_numeric_state();
                            }
                        },
                        .Binary => {
                            if (current == '0' or current == '1') {
                                self.consume();
                            } else {
                                num_state.*.expecting = .size;
                                return self.check_numeric_state();
                            }
                        },
                    }
                },
                .size => {
                    switch (current) {
                        'l' => try num_state.elongate(),
                        's' => try num_state.shorten(),
                        'u' => num_state.*.unsigned = true,
                        'f' => num_state.*.floating_point = true,
                        else => {
                            try self.push_buffer();
                            return .OutOfDate;
                        },
                    }
                },
            }

            return .Ok;
        }

        fn check_state(self: *Tokenizer) !StateResult {
            switch (self.state) {
                .bad => return .OutOfDate,
                .none => return try self.check_standard_state(),
                .numeric => return try self.check_numeric_state(),
                .string => return try self.check_string_state(),
                .register => return try self.check_register_state(),
            }
        }

        fn tokenize(self: *Tokenizer) !void {
            loop: while (self.idx < self.string.len) {
                if (self.peek() == ';')
                    while(self.peek() != '\n') {
                        self.next();
                        if (self.idx >= self.string.len)
                            break :loop;
                    };

                switch (try self.check_state()) {
                    .OutOfDate => self.switch_state(),
                    else => {},
                }
                self.next();
            }

            try self.push_buffer();
        }
    };

    pub fn init(gpa: std.mem.Allocator, string: []const u8) !TokenStream {
        var tokenizer = try Tokenizer.init(gpa, string);
        try tokenizer.tokenize();
        return try tokenizer.finish();
    }

    pub fn deinit(self: *TokenStream, gpa: std.mem.Allocator) void {
        for (self.tokens) |*token| {
            token.deinit(gpa);
        }

        gpa.free(self.tokens);
    }

    pub fn format(self: *const TokenStream, writer: *std.io.Writer) std.Io.Writer.Error!void {
        for (self.tokens) |token| {
            try writer.print("{f} ", .{token});
        }
    }
};
