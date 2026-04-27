//! Org-Asm Tokens
//! 4/26/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const proc = @import("procedure.zig");
const Procedure = proc.Procedure;
const Tag = proc.Tag;
// ----- INCLUDES

pub const Token = union(enum) {
    Procedure: Procedure,
    Tag: Tag,
    Identifier: u64,
    Data: []const u8,

    pub fn deinit(self: *Token, gpa: std.mem.Allocator) void {
        switch (self.*) {
            .Data => |d| {
                gpa.free(d);
            },
            else => {},
        }
    }

    pub fn format(self: *const Token, writer: *std.io.Writer) std.Io.Writer.Error!void {
        switch (self.*) {
            .Procedure => try writer.print("PROC", .{}),
            .Tag => try writer.print("TAG", .{}),
            .Identifier => try writer.print("IDENT", .{}),
            .Data => try writer.print("DATA", .{}),
        }
    }
};
