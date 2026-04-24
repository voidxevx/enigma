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
/// 
/// The abstract syntax tree or AST is a tree representation
/// of the flow of execution for operators. The operator consists of two node 
/// types: Null denotation (NUD) essentially leaf nodes and Left denotation (LED) branching nodes.
/// Null denotations are single objects or unary operators that either hold a single value or another
/// node. Left denotations hold a left and right half of a tree. 
pub const SyntaxTree = struct {
    /// The head node of the AST
    head: INode,

    /// Node Interface
    /// 
    /// Interface class for AST Nodes. Since Zig has no form of polymorphism built in 
    /// I must implement it manually via vtables. The Interface Node class wrappes an opaque
    /// pointer to the object as well as a vtable containing all of its methods. This is identical
    /// to how polymorphism and virtual functions work in every other language.
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

    /// Binary Operator Node (Left Denotation)
    /// 
    /// Represents a binary operator with a left and right value.
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

    /// Unary Operator Node (Null Denotation)
    /// 
    /// Represents a unary operator with a single contained value.
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

    /// Literal Node (Null Denotation)
    /// 
    /// Represents a single static literal
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

    /// Identifier Node (Null Denotation)
    /// 
    /// Represents an identifier.
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

    /// Parser
    /// 
    /// Converts a token stream into an AST. This implementation 
    /// uses the classing Pratt Parsing algoritm. 
    const Parser = struct {
        /// The token stream being parsed
        token_stream: TokenStream,
        /// The current index within the token stream
        idx: usize = 0,
        // General purpose allocator
        gpa: std.mem.Allocator,

        /// Possible parsing errors
        const ParseError = error {
            /// Couldnt generate a null denotation from a token
            NoNUDForToken,
            /// Couldnt generate a left denotation from a token
            NoLEDForToken,
            /// Expected a right prenthetical
            ExpectedRightParenthetical,
        } || anyerror;

        /// peeks the current token being parsed
        fn peek(self: *const Parser) *const Token {
            return &self.token_stream.tokens[self.idx];
        }

        /// precedes to the next token in the stream
        fn next(self: *Parser) void {
            self.*.idx += 1;
        }

        /// Generates a null denotation
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

        /// Generates a left denotation
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

        /// Parses an expression
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

    var stream = TokenStream.init(
        gpa, 
        .{
            .operators = &operators,
            .keywords = &[_]*const tokens_stream.TokenStream.Keyword {}
        }, 
        "5 * (1 + 1)"
    ) catch @panic("Failed to tokenize string");
    defer stream.deinit(gpa);

    std.debug.print("{f}\n", .{stream});

    var ast = SyntaxTree.init(gpa, stream) catch @panic("Failed to create AST");
    defer ast.deinit(gpa);

    std.debug.print("{f}\n", .{ast});
}