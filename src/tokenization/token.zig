const std = @import("std");
const ObjectLiteral = @import("../literals.zig").ObjectLiteral;

pub const TokenType = union(enum) {
    identifier: []const u8,
    literal: ObjectLiteral,

    pub fn format(
        self: TokenType, 
        comptime _: []const u8, 
        _: std.fmt.FormatOptions, 
        writer: anytype
    ) !void {
        switch (self) {
            .identifier => |ident| {
                writer.print("{}", ident);
            },

            .literal => |lit| {
                writer.print("{}", lit);
            }
        }
    }
};

pub const Token = struct {
    token_type: TokenType,
    line: ?usize,
    column_start: ?usize,
    column_end: ?usize,

    pub fn to_string(self: *Token) ![]const u8 {
        var buffer: [64]u8 = undefined;
        return try std.fmt.bufPrint(
            &buffer, 
            "ln: {d}, {d}:{d}", 
            .{ 
                self.line orelse 0, 
                self.column_start orelse 0, 
                self.column_end orelse 0
            }
        );
    }
};

pub const TokenPackage = struct {
    tokens: []Token,
    file_origin: ?[]const u8
};