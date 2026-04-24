//! # Parser
//! 4/23/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const Operator = @import("operator.zig").Operator;
const objects = @import("objects.zig");
const tokens_stream = @import("token-stream.zig");
const TokenStream = tokens_stream.TokenStream;
const Token = tokens_stream.TokenStream.Token;
// ----- INCLUDES


/// Abstract Syntax Tree (AST)
pub const SyntaxTree = struct {
    head: INode,

    const INode = struct {
        ptr: *anyopaque,
        vtable: *const VTable,

        const VTable = struct {
            format: ?*const fn (*const anyopaque, *std.io.Writer) std.Io.Writer.Error!void = null,
            deinit: *const fn (*anyopaque, gpa: std.mem.Allocator) void,
        };

        pub fn format(self: *const INode, writer: *std.io.Writer) std.Io.Writer.Error!void {
            if (self.vtable.format) |_format| {
                try _format(self.ptr, writer);
            } else {
                try writer.print("No Format!", .{});
            }
        }

        fn deinit(self: *INode, gpa: std.mem.Allocator) void {
            self.vtable.deinit(self.ptr, gpa);
        }
    };

    const Node_LED_BinaryOperator = struct {
        left: INode,
        right: INode,
        operator: *const Operator,

        fn interface(self: *Node_LED_BinaryOperator) INode {
            return .{
                .ptr = self,
                .vtable = &.{
                    .format = Node_LED_BinaryOperator.format,
                    .deinit = Node_LED_BinaryOperator.deinit,
                }
            };
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_LED_BinaryOperator = @ptrCast(@alignCast(ptr));
            self.left.deinit(gpa);
            self.right.deinit(gpa);
            gpa.destroy(self);
        }

        fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_LED_BinaryOperator = @ptrCast(@alignCast(ptr));
            try writer.print("({f} {s} {f})", .{self.left, self.operator.symbol, self.right});
        }
    };

    const Node_NUD_UnaryOperator = struct {
        operator: *const Operator,
        inner: INode,

        fn interface(self: *Node_NUD_UnaryOperator) INode {
            return .{
                .ptr = self,
                .vtable = &.{
                    .format = Node_NUD_UnaryOperator.format,
                    .deinit = Node_NUD_UnaryOperator.deinit,
                }
            };
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_UnaryOperator = @ptrCast(@alignCast(ptr));
            self.inner.deinit(gpa);
            gpa.destroy(self);
        }

        fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_NUD_UnaryOperator = @ptrCast(@alignCast(ptr));
            try writer.print("({s} {f})", .{self.operator.symbol, self.inner});
        }
    };

    const Node_NUD_Literal = struct {
        value: objects.Object,

        fn interface(self: *Node_NUD_Literal) INode {
            return .{
                .ptr = self,
                .vtable = &.{
                    .format = Node_NUD_Literal.format,
                    .deinit = Node_NUD_Literal.deinit,
                }
            };
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_Literal = @ptrCast(@alignCast(ptr));
            gpa.destroy(self);
        }

        fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_NUD_Literal = @ptrCast(@alignCast(ptr));
            try self.value.format(writer);
        }
    };

    const Node_NUD_Identifier = struct {
        identifier: objects.IdentifierHash,

        fn interface(self: *Node_NUD_Identifier) INode {
            return .{
                .ptr = self,
                .vtable = &.{
                    .format = Node_NUD_Identifier.format,
                    .deinit = Node_NUD_Identifier.deinit,
                }
            };
        }

        fn deinit(ptr: *anyopaque, gpa: std.mem.Allocator) void {
            const self: *Node_NUD_Identifier = @ptrCast(@alignCast(ptr));
            gpa.destroy(self);
        }

        fn format(ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
            const self: *const Node_NUD_Identifier = @ptrCast(@alignCast(ptr));
            try writer.print("IDENT({d})", .{self.identifier});
        }
    };

    const Parser = struct {
        token_stream: TokenStream,
        idx: usize = 0,
        gpa: std.mem.Allocator,

        const ParseError = error {
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

        fn nud(self: *Parser, token: *const Token) ParseError!INode {
            switch (token.*) {
                .Identifier => |id| {
                    var node = try self.gpa.create(Node_NUD_Identifier);
                    node.*.identifier = id;

                    return node.interface();
                },

                .Literal => |lit| {
                    var node = try self.gpa.create(Node_NUD_Literal);
                    node.*.value = lit;
                    
                    return node.interface();
                },


                .LeftParen => {
                    self.next();
                    const node = try self.expr(0);
                    if (self.peek().* != .RightParen) {
                        std.debug.print("Expected right parenthetical!\n", .{});
                        return ParseError.ExpectedRightParenthetical;
                    }
                    return node;
                },

                .Operator => |op| {
                    if (op.prefix_binding_power == null) {
                        std.debug.print("Operator doesn't implement a unary usage: {s}\n", .{op.symbol});
                        return ParseError.NoNUDForToken;
                    }

                    var node = try self.gpa.create(Node_NUD_UnaryOperator);
                    node.*.operator = op;
                    node.*.inner = try self.expr(op.prefix_binding_power.?);

                    return node.interface();
                },

                else => {
                    std.debug.print("No LED Node can be generated from token: {f}\n", .{token});
                    return ParseError.NoNUDForToken;
                },
            }
        }

        fn led(self: *Parser, token: *const Token, left: INode) ParseError!INode {
            switch (token.*) {
                .Operator => |op| {
                    if (op.infix_binding_power == null) {
                        std.debug.print("Operator doesn't implement a binary usage: {s}\n", .{op.symbol});
                        return ParseError.NoLEDForToken;
                    }

                    var node = try self.gpa.create(Node_LED_BinaryOperator);
                    node.*.operator = op;
                    node.*.left = left;
                    node.*.right = try self.expr(op.infix_binding_power.?);

                    return node.interface();
                },

                else => {
                    std.debug.print("Cannot generate LED Node from token: {f}\n", .{token});
                    return ParseError.NoLEDForToken;
                },
            }
        }

        fn expr(self: *Parser, current_binding_power: i32) ParseError!INode {
            var left = try self.nud(self.peek());
            self.next();

            while (self.peek().left_binding_power() > current_binding_power) {
                const current = self.peek();
                self.next();
                left = try self.led(current, left);
            }

            return left;
        }
    };

    pub fn init(gpa: std.mem.Allocator, stream: TokenStream) !SyntaxTree {
        var parser: Parser = .{ .token_stream = stream, .gpa = gpa };
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

pub export fn test_ast() void {
    const gpa = std.heap.page_allocator;

    var operators = [_]*const Operator {
        &.{
            .symbol = "+",
            .infix_binding_power = 3,
        },
        &.{
            .symbol = "-",
            .infix_binding_power = 3,
            .prefix_binding_power= 2,
        },
        &.{
            .symbol = "*",
            .infix_binding_power = 4,
            .prefix_binding_power = 2,
        },
        &.{
            .symbol = "/",
            .infix_binding_power = 4,
        }
    };

    const stream = TokenStream.init(
        gpa, 
        .{
            .operators = &operators,
            .keywords = &[_]*const tokens_stream.TokenStream.Keyword {}
        }, 
        "5 * (1 + 1)"
    ) catch @panic("Failed to tokenize string");

    std.debug.print("{f}\n", .{stream});

    const ast = SyntaxTree.init(gpa, stream) catch @panic("Failed to create AST");

    std.debug.print("{f}\n", .{ast});
}