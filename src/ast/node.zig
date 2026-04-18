//! # Node
//! 4/17/2026 - Nyx
//! 
//! Abstract Syntax Tree nodes.

// INCLUDES
const std = @import("std");

/// Node interface
/// 
/// Manual polymorphism for AST nodes
/// 
/// This is a very standard pattern in zig that allows for vtables.
/// Rust does this in its backend when using any dyn traits.
/// 
/// # Trait Methods
/// * `format` - (optional) Prints out the node in a formatted view. Allows the token to be printed in a formatted string.
pub const INode = struct {
    /// Pointer to the actual node.
    ptr: *anyopaque,

    /// Pointer to the virtual table
    vtable: *const NodeVTable,

    /// Node virtual table functions.
    pub const NodeVTable = struct {
        /// Format method implementation.
        format: ?*const fn (ptr: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void = null,
    };

    /// Format function for the node.
    /// 
    /// Allows the node to be printed using "{f}" in a formatted string.
    pub fn format(self: *const INode, writer: *std.io.Writer) std.Io.Writer.Error!void {
        if (self.vtable.format) |formatting|{
            try formatting(self.ptr, writer);
        } else {
            try writer.print("No Format!", .{});
        }
    }
};


/// Null Node
/// 
/// Used as a placeholder where their are no tokens or functionality.
pub const NullNode = struct {

    pub fn interface(self: *NullNode) INode {
        return INode {
            .ptr = self,
            .vtable = &.{
                .format = NullNode.format,
            }
        };
    }

    pub fn format(_: *const anyopaque, writer: *std.io.Writer) std.Io.Writer.Error!void {
        try writer.print("Null", .{});
    }
};


pub const BinaryNode = struct {
    left_node: INode,
    right_node: INode,
    symbol: []const u8,

    pub fn interface(self: *BinaryNode) INode {
        return .{
            .ptr = self,
            .vtable = &.{
                .format = BinaryNode.format,
            }
        };
    }

    pub fn format(
        ptr: *const anyopaque,
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        _ = ptr;
        // const self: *const BinaryNode = @ptrCast(@alignCast(ptr));
        try writer.print("|- bin\n|- L\n|- R", .{});
    }
};