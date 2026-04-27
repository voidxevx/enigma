//! Org-Asm Tokens
//! 4/26/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const proc = @import("procedure.zig");
const Procedure = proc.Procedure;
const Tag = proc.Tag;
// ----- INCLUDES

pub const RegisterData = struct { 
    id: u8 = 0, 
    size: enum(u2) {
        large,
        default,
        small,
    } = .default,

    pub fn is_valid(self: RegisterData) bool {
        switch (self.size) {
            .small => return self.id > 0 and self.id <= 4,
            .default => return self.id > 0 and self.id <= 8,
            .large => return self.id > 0 and self.id <= 2,
        }
    }
};

pub const Token = union(enum) {
    Procedure: Procedure,
    Tag: Tag,
    Identifier: u64,
    Register: RegisterData,
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
            .Register => |r| {
                switch (r.size) {
                    .large => try writer.print("rl{d}", .{r.id}),
                    .default => try writer.print("r{d}", .{r.id}),
                    .small => try writer.print("rs{d}", .{r.id}),
                }
            },
            .Data => |d| try writer.print("D:{d}", .{d.len}),
        }
    }
};
