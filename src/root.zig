//! # Enigma
//! 4/18/2026 - Nyx

// INCLUDES -----
const std = @import("std");
// ----- INCLUDES

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
    EOF,

    pub fn format(self: *const Token, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self.*) {
            .Identifier => |id| try writer.print("\x1b[4;33m{c}\x1b[0m", .{id}),
            .Int => |i| try writer.print("{d}", .{i}),
            .Operator => |op| try writer.print("{f}", .{op}),
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
        var buffer = try gpa.alloc(Token, str.len + 1);
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

        buffer[token_count] = .EOF;
        token_count += 1;

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
pub const SyntaxTree = struct {
    head: INode,

    pub const INode = struct {
        ptr: *anyopaque,
        vtable: *const VTable,

        pub const VTable = struct {
            format: ?*const fn (*const anyopaque, *std.io.Writer) std.Io.Writer.Error!void = null,
            deinit: ?*const fn (*anyopaque, std.mem.Allocator) void = null,
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
    };

    const Node_NUD_Identifier = struct {
        identifier: u8,

        fn interface(self: *Node_NUD_Identifier) INode {
            return .{ 
                .ptr = self, 
                .vtable = &.{
                    .format = Node_NUD_Identifier.format,
                    .deinit = Node_NUD_Identifier.deinit,
                } 
            };
        }

        pub fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_NUD_Identifier = @ptrCast(@alignCast(ptr));
            try writer.print("{c}", .{self.identifier});
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_Identifier = @ptrCast(@alignCast(ptr));
            gpa.destroy(self);
        }
    };

    const Node_NUD_Integer = struct {
        int: u8,

        fn interface(self: *Node_NUD_Integer) INode {
            return .{ 
                .ptr = self, 
                .vtable = &.{
                    .format = Node_NUD_Integer.format,
                    .deinit = Node_NUD_Integer.deinit,
                } 
            };
        }

        pub fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_NUD_Integer = @ptrCast(@alignCast(ptr));
            try writer.print("{d}", .{self.int});
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_Integer = @ptrCast(@alignCast(ptr));
            gpa.destroy(self);
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
                }
            };
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_LED_Operator = @ptrCast(@alignCast(ptr));
            self.left.deinit(gpa);
            self.right.deinit(gpa);
            gpa.destroy(self);
        }

        pub fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_LED_Operator = @ptrCast(@alignCast(ptr));
            try writer.print("({f} {c} {f})", .{self.left, self.operator.symbol, self.right});
        }
    };

    const Parser = struct {
        token_stream: TokenStream,
        idx: usize = 0,
        gpa: std.mem.Allocator,

        const ParsingError = error{
            NoNUDForToken,
            NoLEDForToken,
        };

        const Error = ParsingError || anyerror;

        fn peek(self: *const Parser) *const Token {
            return &self.token_stream.tokens[self.idx];
        }

        fn next(self: *Parser) void {
            self.*.idx += 1;
        }

        fn nud(self: *const Parser, token: *const Token) Error !INode {
            switch (token.*) {
                .Identifier => |id| {
                    var node = try self.gpa.create(Node_NUD_Identifier);
                    node.*.identifier = id;

                    return node.interface();
                },

                .Int => |i| {
                    var node = try self.gpa.create(Node_NUD_Integer);
                    node.*.int = i;

                    return node.interface();
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

// ----- INTERPRETING