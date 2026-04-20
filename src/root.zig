//! # Enigma
//! 4/18/2026 - Nyx

// INCLUDES -----
const std = @import("std");
// ----- INCLUDES

// LEXICS -----
pub const Operator = struct {
    symbol: []const u8,
    infix_binding_power: i32,
    resolve: *const fn(*Interpreter) anyerror!void,

    pub fn format(self: *const Operator, writer: *std.io.Writer) std.Io.Writer.Error!void {
        try writer.print("\x1b[4m{s}\x1b[0m", .{self.symbol});
    }
};

pub const ObjectLiteral = union(enum) {
    Integer: i64,
    Float: f64,

    pub fn format(self: *const ObjectLiteral, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self.*) {
            .Integer => |i| try writer.print("{d}", .{i}),
            .Float => |f| try writer.print("{d}", .{f}),
        }
    }
};

pub const Token = union(enum) {
    Literal: ObjectLiteral,
    IdentifierHash: u64,
    Operator: *const Operator,
    LeftParenthetical,
    RightParenthetical,
    EOF,

    pub fn format(self: *const Token, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self.*) {
            .IdentifierHash => try writer.print("IDENT", .{}),
            .Literal => |lit| try lit.format(writer),
            .Operator => |op| try writer.print("{f}", .{op}),
            .LeftParenthetical => try writer.print("(", .{}),
            .RightParenthetical => try writer.print(")", .{}),
            .EOF => try writer.print("eof", .{}),
        }
    }

    pub fn get_infix_binding_power(self: *const Token) i32 {
        switch (self.*) {
            .Operator => |op| return op.infix_binding_power,
            .EOF => return -1,
            else => return 0,
        }
    }
};

pub const TokenStream = struct {
    tokens: []Token,
    token_count: usize,

    pub const Tokenizer = struct {
        const TOKENIZER_BUFFER_CAPACITY: usize = 128;
        const DEFAULT_TOKEN_CAPACITY: usize = 16;

        string: []const u8,
        config: TokenConfig,
        gpa: std.mem.Allocator,
        tokens: []Token,
        buffer: []u8,

        buffer_size: usize = 0,
        idx: usize = 0,
        token_count: usize = 0,
        token_capacity: usize = DEFAULT_TOKEN_CAPACITY,
        state: TokenizationState = .None,
        num_state: ?NumericObjectState = null,

        pub const TokenConfig = struct {
            operators: std.ArrayList(Operator),

            fn check_operator(self: *const TokenConfig, symbol: []const u8) ?*const Operator {
                for (self.operators.items) |*op| {
                    if (std.mem.eql(u8, symbol, op.symbol))
                        return op;
                }

                return null;
            }
        };

        const NumericObjectState = struct {
            floating_point: bool = false,
        };

        const TokenizationState = enum {
            None,
            Symbolic,
            Alphabetic,
            Numeric,
        };

        const StateResult = enum {
            Ok,
            OutOfDate,
        };

        fn check_alphabetic_state(self: *Tokenizer) !StateResult {
            if (std.ascii.isAlphanumeric(self.peek())) {
                try self.consume_character();
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
                try self.consume_character();
                return .Ok;
            }
        }

        fn check_numeric_state(self: *Tokenizer) !StateResult {
            const current = self.peek();
            if (std.ascii.isDigit(current)) {
                try self.consume_character();
            } else if (current == '.' and !self.num_state.?.floating_point) {
                self.*.num_state.?.floating_point = true;
                try self.consume_character();
            } else {
                try self.push_buffer();
                return .OutOfDate;
            }

            return .Ok;
        }

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

        fn switch_state(self: *Tokenizer) void {
            const current = self.peek();
            self.*.num_state = null;

            if (std.ascii.isDigit(current)) {
                self.*.state = .Numeric;
                self.*.num_state = .{};
            } else if (std.ascii.isAlphabetic(current)) {
                self.*.state = .Alphabetic;
            } else {
                self.*.state = .Symbolic;
            }
        }

        fn consume_character(self: *Tokenizer) !void {
            self.*.buffer[self.buffer_size] = self.peek();
            self.*.buffer_size += 1;
        }

        fn peek(self: *Tokenizer) u8 {
            return self.string[self.idx];
        }

        fn next(self: *Tokenizer) void {
            self.*.idx += 1;
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
            } else {
                try self.push_token(.{ .IdentifierHash = std.hash.Wyhash.hash(0, string)});
            }
        }

        fn push_numeric_token(self: *Tokenizer, string: []const u8) !void {
            const state = self.num_state.?;
            if (state.floating_point) {
                const val: f64 = try std.fmt.parseFloat(f64, string);
                const token: Token = .{
                    .Literal = .{ .Float = val }
                };
                try self.push_token(token);
            } else {
                const val: i64 = try std.fmt.parseInt(i64, string, 10);
                const token: Token = .{
                    .Literal = .{ .Integer = val }
                };
                try self.push_token(token);
            }
        }

        fn push_buffer(self: *Tokenizer) !void {
            if (self.buffer_size == 0)
                return;

            defer self.*.buffer_size = 0;
            switch (self.state) {
                .Numeric => 
                    try self.push_numeric_token(self.buffer[0..self.buffer_size]),

                else =>
                    try self.push_keyword_token(self.buffer[0..self.buffer_size]),
            }
        }

        fn check_parenthetical(self: *Tokenizer) !bool {
            switch (self.peek()) {
                '(' => {
                    try self.push_buffer();
                    try self.push_token(.LeftParenthetical);
                },
                ')' => {
                    try self.push_buffer();
                    try self.push_token(.RightParenthetical);
                },
                else => return false,
            }
            return true;
        }

        pub fn init(string: []const u8, config: TokenConfig, gpa: std.mem.Allocator) !Tokenizer {
            return .{
                .string = string,
                .config = config,
                .gpa = gpa,
                .tokens = try gpa.alloc(Token, DEFAULT_TOKEN_CAPACITY),
                .buffer = try gpa.alloc(u8, TOKENIZER_BUFFER_CAPACITY),
            };
        }

        pub fn finish(self: *Tokenizer) !TokenStream {
            defer self.gpa.free(self.buffer);
            defer self.gpa.free(self.tokens);

            const finalized_buffer = try self.gpa.alloc(Token, self.token_count);
            @memcpy(finalized_buffer, self.tokens[0..self.token_count]);

            return .{
                .tokens = finalized_buffer,
                .token_count = self.token_count,
            };
        }

        pub fn tokenize(self: *Tokenizer) !void {
            while(self.idx < self.string.len) {
                defer self.next();
                if (std.ascii.isWhitespace(self.peek())) {
                    try self.push_buffer();
                    self.*.state = .None;
                } else if (try self.check_parenthetical()) {
                    self.*.state = .None;
                } else if (try self.check_state() == .OutOfDate) {
                    self.switch_state();
                    try self.consume_character();
                }
            }

            try self.push_buffer();
            try self.push_token(.EOF);
        }
    };

    pub fn init(gpa: std.mem.Allocator, string: []const u8, config: Tokenizer.TokenConfig) !TokenStream {
        var tokenizer = try Tokenizer.init(string, config, gpa);
        try tokenizer.tokenize();
        return tokenizer.finish();
    }

    pub fn deinit(self: *TokenStream, gpa: std.mem.Allocator) void {
        gpa.free(self.tokens);
    }

    pub fn format(self: *const TokenStream, writer: *std.io.Writer) std.Io.Writer.Error!void {
        for (self.tokens) |token| 
            try writer.print("{f} ", .{token});
    }
};
// ----- LEXICS

// PARSING -----
pub const SyntaxTree = struct {
    head: INode,

    pub const INode = struct {
        ptr: *anyopaque,
        vtable: *const VTable,

        pub const VTable = struct {
            format: ?*const fn (*const anyopaque, *std.io.Writer) std.Io.Writer.Error!void = null,
            deinit: ?*const fn (*anyopaque, std.mem.Allocator) void = null,
            resolve: *const fn (*anyopaque, *Interpreter) anyerror!void,
        };

        pub fn format(self: *const INode, writer: *std.io.Writer) std.Io.Writer.Error!void {
            if (self.vtable.format) |_format| {
                try _format(self.ptr, writer);
            } else {
                try writer.print("No Format!", .{});
            }
        }

        pub fn deinit(self: *INode, gpa: std.mem.Allocator) void {
            if (self.vtable.deinit) |_deinit|
                _deinit(self.ptr, gpa);
        }

        pub fn resolve(self: *INode, interpreter: *Interpreter) !void {
            try self.vtable.resolve(self.ptr, interpreter);
        }
    };

    const Node_NUD_Identifier = struct {
        identifier: u64,

        fn interface(self: *Node_NUD_Identifier) INode {
            return .{ 
                .ptr = self, 
                .vtable = &.{
                    .format = Node_NUD_Identifier.format,
                    .deinit = Node_NUD_Identifier.deinit,
                    .resolve = Node_NUD_Identifier.resolve,
                }
            };
        }

        pub fn format(_: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            try writer.print("IDENT", .{});
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_Identifier = @ptrCast(@alignCast(ptr));
            gpa.destroy(self);
        }

        fn resolve(ptr: *anyopaque, interpreter: *Interpreter) anyerror!void {
            const self: *Node_NUD_Identifier = @ptrCast(@alignCast(ptr));
            try interpreter.push(.{ .Identifier = self.identifier });
        }
    };

    const Node_NUD_Literal = struct {
        lit: ObjectLiteral,

        fn interface(self: *Node_NUD_Literal) INode {
            return .{ 
                .ptr = self, 
                .vtable = &.{
                    .format = Node_NUD_Literal.format,
                    .deinit = Node_NUD_Literal.deinit,
                    .resolve = Node_NUD_Literal.resolve,
                } 
            };
        }

        pub fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_NUD_Literal = @ptrCast(@alignCast(ptr));
            try writer.print("{f}", .{self.lit});
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_Literal = @ptrCast(@alignCast(ptr));
            gpa.destroy(self);
        }

        fn resolve(ptr: *anyopaque, interpreter: *Interpreter) anyerror!void {
            const self: *Node_NUD_Literal = @ptrCast(@alignCast(ptr));
            try interpreter.push(.{ .Literal = self.lit });
        }
    };

    const Node_LED_Operator = struct {
        operator: *const Operator,
        left: INode,
        right: INode,

        fn interface(self: *Node_LED_Operator) INode {
            return .{ 
                .ptr = self, 
                .vtable = &.{
                    .format = Node_LED_Operator.format,
                    .deinit = Node_LED_Operator.deinit,
                    .resolve = Node_LED_Operator.resolve,
                }
            };
        }

        pub fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_LED_Operator = @ptrCast(@alignCast(ptr));
            try writer.print("({f} {s} {f})", .{self.left, self.operator.symbol, self.right});
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_LED_Operator = @ptrCast(@alignCast(ptr));
            self.left.deinit(gpa);
            self.right.deinit(gpa);
            gpa.destroy(self);
        }

        fn resolve(ptr: *anyopaque, interpreter: *Interpreter) anyerror!void {
            const self: *Node_LED_Operator = @ptrCast(@alignCast(ptr));
            try self.left.resolve(interpreter);
            try self.right.resolve(interpreter);
            try self.operator.resolve(interpreter);
        }
    };

    const Parser = struct {
        token_stream: TokenStream,
        idx: usize = 0,
        gpa: std.mem.Allocator,

        const Error = error{
            NoNUDForToken,
            NoLEDForToken,
            ExpectedRightParenthetical,
        } || anyerror;

        fn peek(self: *const Parser) *const Token {
            return &self.token_stream.tokens[self.idx];
        }

        fn next(self: *Parser) void {
            self.*.idx += 1;
        }

        fn nud(self: *Parser, token: *const Token) Error !INode {
            switch (token.*) {
                .IdentifierHash => |id| {
                    var node = try self.gpa.create(Node_NUD_Identifier);
                    node.*.identifier = id;

                    return node.interface();
                },

                .Literal => |lit| {
                    var node = try self.gpa.create(Node_NUD_Literal);
                    node.*.lit = lit;

                    return node.interface();
                },

                .LeftParenthetical => {
                    self.next();
                    const node = try self.expr(0);
                    if (self.peek().* != .RightParenthetical)
                        return Error.ExpectedRightParenthetical;
                    return node;
                },

                else => return Error.NoNUDForToken,
            }
        }

        fn led(self: *Parser, token: *const Token, left: INode) Error!INode {
            switch (token.*) {
                .Operator => |op| {
                    var node = try self.gpa.create(Node_LED_Operator);
                    node.*.operator = op;
                    node.*.left = left;
                    node.*.right = try self.expr(op.infix_binding_power);

                    return node.interface();
                },

                else => return Error.NoLEDForToken,
            }
        }

        fn expr(self: *Parser, right_binding_power: i32) Error!INode {
            var left = try self.nud(self.peek());
            self.next();

            while (self.peek().get_infix_binding_power() > right_binding_power) {
                const current = self.peek();
                self.next();

                left = try self.led(current, left);
            }

            return left;
        }
    };

    pub fn init(gpa: std.mem.Allocator, token_stream: TokenStream) !SyntaxTree {
        var parser: Parser = .{ .token_stream = token_stream, .gpa = gpa };
        const head = try parser.expr(0);

        return .{ .head = head };
    }

    pub fn deinit(self: *SyntaxTree, gpa: std.mem.Allocator) void {
        self.head.deinit(gpa);
    }

    pub fn format(self: *const SyntaxTree, writer: *std.io.Writer) std.Io.Writer.Error!void {
        try self.head.format(writer);
    }
};
// ----- PARSING


// INTERPRETING -----
pub const Object = union(enum) {
    Literal: ObjectLiteral,
    Identifier: u64,

    pub fn format(self: *const Object, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self.*) {
            .Identifier => try writer.print("IDENT", .{}),
            .Literal => |lit| try lit.format(writer),
        }
    }
};

pub const Interpreter = struct {
    const DEFAULT_STACK_CAPACITY: usize = 16;

    heap: std.AutoHashMap(u64, Object),
    stack: []Object,
    stack_ptr: usize = 0,
    stack_capacity: usize = DEFAULT_STACK_CAPACITY,
    gpa: std.mem.Allocator,

    pub fn init(gpa: std.mem.Allocator) !Interpreter {
        return .{
            .heap = .init(gpa),
            .stack = try gpa.alloc(Object, DEFAULT_STACK_CAPACITY),
            .gpa = gpa,
        };
    }

    pub fn deinit(self: *Interpreter) void {
        self.heap.deinit();
        self.gpa.free(self.stack);
    }

    pub fn flush(self: *Interpreter) !void {
        self.stack_capacity = DEFAULT_STACK_CAPACITY;
        self.stack_ptr = 0;
        self.stack = try self.gpa.realloc(self.stack, DEFAULT_STACK_CAPACITY);
    }

    pub fn push(self: *Interpreter, val: Object) !void {
        if (self.stack_ptr >= self.stack_capacity) {
            self.*.stack_capacity *= 2;
            self.*.stack = try self.gpa.realloc(self.stack, self.stack_capacity);
        }

        self.*.stack[self.stack_ptr] = val;
        self.*.stack_ptr += 1;
    }

    pub fn pop(self: *Interpreter) ?Object {
        if (self.stack_ptr == 0)
            return null;

        self.*.stack_ptr -= 1;
        return self.stack[self.stack_ptr];
    }

    // pub fn emplace_variable(self: *Interpreter, identifier: u8, value: u8) !void {
    //     try self.heap.put(identifier, value);
    // }

    // pub fn get_variable(self: Interpreter, identifier: u8) ?u8 {
    //     return self.heap.get(identifier);
    // }

    pub fn run(self: *Interpreter, ast: *SyntaxTree) !?Object {
        try ast.head.resolve(self);
        return self.pop();
    }
};
// ----- INTERPRETING

// OPERATIONS -----
pub fn add(interpreter: *Interpreter) anyerror!void {
    const r = interpreter.pop();
    const l = interpreter.pop();

    if (l) |l_val| 
    if (r) |r_val| {
        switch (l_val) {
        .Literal => |l_lit|
            switch (r_val) {
            .Literal => |r_lit|
                switch (l_lit) {
                .Integer => |l_int|
                    switch (r_lit) {
                    .Integer => |r_int|
                        try interpreter.push(.{ .Literal = .{ .Integer = l_int + r_int } }),
                    .Float => |r_float| {
                        const l_float: f64 = @floatFromInt(l_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float + r_float } });
                    }
                    },
                .Float => |l_float|
                    switch (r_lit) {
                    .Integer => |r_int| {
                        const r_float: f64 = @floatFromInt(r_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float + r_float } });
                    },
                    .Float => |r_float| 
                        try interpreter.push(.{ .Literal = .{ .Float = l_float + r_float } })
                    }
                },
            else => {}
            },
        else => {}
        }
    };
}

pub fn mul(interpreter: *Interpreter) anyerror!void {
    const r = interpreter.pop();
    const l = interpreter.pop();

    if (l) |l_val| 
    if (r) |r_val| {
        switch (l_val) {
        .Literal => |l_lit|
            switch (r_val) {
            .Literal => |r_lit|
                switch (l_lit) {
                .Integer => |l_int|
                    switch (r_lit) {
                    .Integer => |r_int|
                        try interpreter.push(.{ .Literal = .{ .Integer = l_int * r_int } }),
                    .Float => |r_float| {
                        const l_float: f64 = @floatFromInt(l_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float * r_float } });
                    }
                    },
                .Float => |l_float|
                    switch (r_lit) {
                    .Integer => |r_int| {
                        const r_float: f64 = @floatFromInt(r_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float * r_float } });
                    },
                    .Float => |r_float| 
                        try interpreter.push(.{ .Literal = .{ .Float = l_float * r_float } })
                    }
                },
            else => {}
            },
        else => {}
        }
    };
}

pub fn sub(interpreter: *Interpreter) anyerror!void {
    const r = interpreter.pop();
    const l = interpreter.pop();

    if (l) |l_val| 
    if (r) |r_val| {
        switch (l_val) {
        .Literal => |l_lit|
            switch (r_val) {
            .Literal => |r_lit|
                switch (l_lit) {
                .Integer => |l_int|
                    switch (r_lit) {
                    .Integer => |r_int|
                        try interpreter.push(.{ .Literal = .{ .Integer = l_int - r_int } }),
                    .Float => |r_float| {
                        const l_float: f64 = @floatFromInt(l_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float - r_float } });
                    }
                    },
                .Float => |l_float|
                    switch (r_lit) {
                    .Integer => |r_int| {
                        const r_float: f64 = @floatFromInt(r_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float - r_float } });
                    },
                    .Float => |r_float| 
                        try interpreter.push(.{ .Literal = .{ .Float = l_float - r_float } })
                    }
                },
            else => {}
            },
        else => {}
        }
    };
}

pub fn div(interpreter: *Interpreter) anyerror!void {
    const r = interpreter.pop();
    const l = interpreter.pop();

    if (l) |l_val| 
    if (r) |r_val| {
        switch (l_val) {
        .Literal => |l_lit|
            switch (r_val) {
            .Literal => |r_lit|
                switch (l_lit) {
                .Integer => |l_int|
                    switch (r_lit) {
                    .Integer => |r_int| {
                        const l_float: f64 = @floatFromInt(l_int);
                        const r_float: f64 = @floatFromInt(r_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float / r_float } });
                    },
                    .Float => |r_float| {
                        const l_float: f64 = @floatFromInt(l_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float / r_float } });
                    }
                    },
                .Float => |l_float|
                    switch (r_lit) {
                    .Integer => |r_int| {
                        const r_float: f64 = @floatFromInt(r_int);
                        try interpreter.push(.{ .Literal = .{ .Float = l_float / r_float } });
                    },
                    .Float => |r_float| 
                        try interpreter.push(.{ .Literal = .{ .Float = l_float / r_float } })
                    }
                },
            else => {}
            },
        else => {}
        }
    };
}

pub fn default_operators(gpa: std.mem.Allocator) !std.ArrayList(Operator) {
    var operators: std.ArrayList(Operator) = .empty;
    try operators.append(gpa, .{
        .symbol = "+",
        .infix_binding_power = 3,
        .resolve = add,
    });

    try operators.append(gpa, .{
        .symbol = "*",
        .infix_binding_power = 4,
        .resolve = mul,
    });

    try operators.append(gpa, .{
        .symbol = "-",
        .infix_binding_power = 3,
        .resolve = sub,
    });

    try operators.append(gpa, .{
        .symbol = "/",
        .infix_binding_power = 4,
        .resolve = div,
    });

    return operators;
}

// ----- OPERATIONS