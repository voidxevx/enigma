//! # Parser
//! 4/23/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const Operator = @import("operator.zig").Operator;
const objects = @import("objects.zig");
// ----- INCLUDES

pub const SyntaxTree = struct {

    const INode = struct {
        ptr: *anyopaque,
        vtable: *const VTable,

        const VTable = struct {
            format: ?*const fn (*const anyopaque, *std.io.Writer) std.Io.Writer.Error!void = null,
            deinit: *const fn (*const anyopaque, gpa: std.mem.Allocator) void,
        };

        fn format(self: *const INode, writer: *std.io.Writer) std.Io.Writer.Error!void {
            if (self.vtable.format) |_format| {
                try _format(self.ptr, writer);
            } else {
                try writer.print("No Format!", .{});
            }
        }

        fn deinit(self: *const INode, gpa: std.mem.Allocator) void {
            self.vtable.deinit(self.ptr, gpa);
        }
    };

    const Node_LED_BinaryOperator = struct {
        left: *const INode,
        right: *const INode,
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
        inner: *const INode,

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
        
    };
};