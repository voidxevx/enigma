const std = @import("std");
const token = @import("token.zig");
const TokenizationError = @import("../errors.zig").TokenizationError;

// Deterministic finite automata

const TokenizationState = enum {
    None,
    Alphabetic,
    Numeric,
    Symbolic,
    String,
};

fn switch_tokenization_state(
    gpa: std.mem.Allocator, 
    current_char: u8, 
    state: *TokenizationState, 
    buffer: *std.ArrayList(u8)
) !void {
    if (current_char == '"') {
        state.* = .String;
    } else if (std.ascii.isAlphabetic(current_char)) {
        state.* = .Alphabetic;
    } else if (std.ascii.isDigit(current_char)) {
        state.* = .Numeric;
    } else {
        state.* = .Symbolic;
    }

    if (state.* != .String) {
        try buffer.append(gpa, current_char);
    }
}

fn push_token(
    gpa: std.mem.Allocator,
    package: *token.TokenPackage,
    buffer: *std.ArrayList(u8),
    line: ?usize,
    column_start: usize,
    column_end: usize
) !void {
    if (buffer.items.len == 0)
        return;
    
    defer buffer.clearRetainingCapacity();

    const token_type: token.TokenType = 
        if (std.mem.eql(u8, buffer.items, "true"))
            token.TokenType {
                .literal = .{ .bool = true }
            }
        else if (std.mem.eql(u8, buffer.items, "false"))
            token.TokenType {
                .literal = .{ .bool = false }
            }
        else buffer_copy: {
            const copy = try buffer.clone(gpa);
            break :buffer_copy token.TokenType {
                .identifier = copy.items
            };
        };

    try package.add_token(.{
        .token_type = token_type,
        .line = line,
        .column_start =  column_start,
        .column_end = column_end,
    });
}

fn push_numeric_token(
    num_state: *NumericState,
    package: *token.TokenPackage,
    buffer: *std.ArrayList(u8),
    line: ?usize,
    column_start: usize,
    column_end: usize
) !void {
    if (buffer.items.len == 0)
        return;

    defer buffer.clearRetainingCapacity();

    const literal = match_literal: {

        switch (num_state.size) {
            .Byte => if (num_state.unsigned) {
                const val = try std.fmt.parseInt(u8, buffer.items, 10);
                break :match_literal token.TokenType { .literal = .{ .ubyte = val }};
            } else {
                const val = try std.fmt.parseInt(i8, buffer.items, 10);
                break :match_literal token.TokenType { .literal = .{ .byte = val }};
            },

            .Short => if (num_state.unsigned) {
                const val = try std.fmt.parseInt(u16, buffer.items, 10);
                break :match_literal token.TokenType { .literal = .{ .ushort = val }};
            } else {
                const val = try std.fmt.parseInt(i16, buffer.items, 10);
                break :match_literal token.TokenType { .literal = .{ .short = val }};
            },

            .Default => {
                if (num_state.floating_point) {
                    const val = try std.fmt.parseFloat(f32, buffer.items);
                    break :match_literal token.TokenType {.literal = .{ .float = val }};
                } else if (num_state.unsigned) {
                    const val = try std.fmt.parseInt(u32, buffer.items, 10);
                    break :match_literal token.TokenType {.literal = .{ .uint = val }};
                } else {
                    const val = try std.fmt.parseInt(i32, buffer.items, 10);
                    break :match_literal token.TokenType {.literal = .{ .int = val }};
                }
            },

            .Long => {
                if (num_state.floating_point) {
                    const val = try std.fmt.parseFloat(f64, buffer.items);
                    break :match_literal token.TokenType {.literal = .{ .double = val }};
                } else if (num_state.unsigned) {
                    const val = try std.fmt.parseInt(u64, buffer.items, 10);
                    break :match_literal token.TokenType {.literal = .{ .ulong = val }};
                } else {
                    const val = try std.fmt.parseInt(i64, buffer.items, 10);
                    break :match_literal token.TokenType {.literal = .{ .long = val }};
                }
            }
        }
    };

    try package.add_token(.{
        .line = line,
        .column_start = column_start,
        .column_end = column_end,
        .token_type = literal,
    });

    num_state.* = .{};
}

const StateResult = enum {
    Ok,
    OutOfDate,
};

fn alphabetic_state(
    gpa: std.mem.Allocator,
    buffer: *std.ArrayList(u8),
    current: u8,
    package: *token.TokenPackage,
    line: ?usize,
    column_start: usize,
    column_end: usize,
) !StateResult {
    if (!std.ascii.isAlphabetic(current)) {
        try push_token(
            gpa, 
            package, 
            buffer, 
            line, 
            column_start, 
            column_end
        );

        return StateResult.OutOfDate;
    } else {
        try buffer.append(gpa, current);
    }

    return StateResult.Ok;
}

fn symbolic_state(
    gpa: std.mem.Allocator,
    buffer: *std.ArrayList(u8),
    current: u8,
    package: *token.TokenPackage,
    line: ?usize,
    column_start: usize,
    column_end: usize,
) !StateResult {
    if (std.ascii.isAlphanumeric(current) or current == '"') {
        try push_token(
            gpa, 
            package, 
            buffer, 
            line, 
            column_start, 
            column_end
        );

        return StateResult.OutOfDate;
    } else {
        try buffer.append(gpa, current);
    }

    return StateResult.Ok;
}

fn numeric_state(
    gpa: std.mem.Allocator,
    state: *NumericState,
    buffer: *std.ArrayList(u8),
    current: u8,
    package: *token.TokenPackage,
    line: ?usize,
    column_start: usize,
    column_end: usize,
) !StateResult {
    switch (current) {
        'u' => {
            state.*.unsigned = true;
            state.*.locked = true;
        },

        'l' => {
            state.*.size = NumericSize.Long;
            state.*.locked = true;
        },

        's' => {
            state.*.locked = true;

            switch (state.size) {
                .Short => {
                    state.*.size = .Byte;
                },

                .Default => {
                    state.*.size = .Short;
                },

                else => {}
            }
        },

        '.' => {
            if (!state.floating_point) {
                try buffer.append(gpa, '.');
                state.*.floating_point = true;
            } else {
                return TokenizationError.MultipleDecimalPointsInFloat;
            }
        },

        else => {
            if (state.locked or !std.ascii.isDigit(current)) {
                try push_numeric_token(
                    state, 
                    package, 
                    buffer, 
                    line, 
                    column_start, 
                    column_end
                );

                return StateResult.OutOfDate;
            } else {
                try buffer.append(gpa, current);
            }
        }
    }     
    

    return StateResult.Ok;
}

const NumericSize = enum {
    Byte,
    Short,
    Default,
    Long,
};

const NumericState = struct {
    size: NumericSize = NumericSize.Default,
    floating_point: bool = false,
    unsigned: bool = false,
    locked: bool = false,
};

fn string_state(
    gpa: std.mem.Allocator,
    state: *TokenizationState,
    buffer: *std.ArrayList(u8),
    current: u8,
    package: *token.TokenPackage,
    line: ?usize,
    column_start: usize,
    column_end: usize,
) !void {
    if (current == '"') {
        const copy = try buffer.clone(gpa);
        try package.add_token(.{
            .token_type = .{ .literal = .{ .string = copy.items} },
            .line = line,
            .column_start = column_start,
            .column_end = column_end,
        });
        state.* = .None;
        buffer.clearRetainingCapacity();
    } else {
        try buffer.append(gpa, current);
    } 
}

pub fn tokenize_string(
    gpa: std.mem.Allocator, 
    string: []const u8, 
    line: ?usize
) !token.TokenPackage {
    var package = try token.TokenPackage.init(null, gpa);

    var state: TokenizationState = .None;
    var num_state: NumericState = .{};

    var buffer = try std.ArrayList(u8).initCapacity(gpa, 128);
    defer buffer.deinit(gpa);

    var idx: usize = 0;
    tokenization_loop: while (idx < string.len) {
        const current = string[idx];

        if (state != .String and std.ascii.isWhitespace(current)) {
            try push_token(gpa, &package, &buffer, line, 0, 0);
            idx += 1;
            continue: tokenization_loop;
        }

        switch (state) {
            .None =>
                try switch_tokenization_state(gpa, current, &state, &buffer),

            .Alphabetic =>
                if (try alphabetic_state(gpa, &buffer, current, &package, line, 0, 0) == .OutOfDate)
                    try switch_tokenization_state(gpa, current, &state, &buffer),
                
            .Symbolic =>
                if (try symbolic_state(gpa, &buffer, current, &package, line, 0, 0) == .OutOfDate)
                    try switch_tokenization_state(gpa, current, &state, &buffer),

            .Numeric => 
                if (try numeric_state(gpa, &num_state, &buffer, current, &package, line, 0, 0) == .OutOfDate)
                    try switch_tokenization_state(gpa, current, &state, &buffer),

            .String =>
                try string_state(gpa, &state, &buffer, current, &package, line, 0, 0,),
        }        

        idx += 1;
    }

    if (state == .Numeric) {
        try push_numeric_token(&num_state, &package, &buffer, line, 0, 0);
    } else {
        try push_token(gpa, &package, &buffer, line, 0, 0);
    }

    return package;
}