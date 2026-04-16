//! # Nodes
//! 4/16/2026 - Rex Bradbury

const std = @import("std");

/// Node interface struct
/// Couples a pointer of an object to its vtable
pub const Node = struct {
    /// opaque pointer to the actual node
    ptr: *anyopaque,
    /// vtable containing implementable functions
    vtable: *const VTable,

    /// Node vtable
    /// 
    /// Map of functions that a node must implement
    pub const VTable = struct {
        test_print: *const fn (ptr: *anyopaque) void
    };

    /// test print function
    pub fn test_print(self: Node) void {
        self.vtable.test_print(self.ptr);
    }
};