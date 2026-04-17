//! # Tokenization Parsing
//! 4/7/2026 - Nyx
//! 
//! Parses a string of text into a package of tokens using a state machine.

// INCLUDES -----
const std = @import("std");
const token = @import("token.zig");
const TokenizationError = @import("../errors.zig").TokenizationError;
// ----- INCLUDES

/// Possible states for the tokenization state machine.
/// 
/// # States
/// * `None` - No state. Default state expecting to change to another state in the next loop.
/// * `Alphabetic` - Alphabetical characters or identifiers.
/// * `Numeric` - Numbers and floating points.
/// * `Symbolic` - Symbols 
/// * `String` - String characters contained in quotes.
const TokenizationState = enum {
    /// No state. Default state expecting to change to another state in the next loop.
    None,

    /// Alphabetical characters or identifiers.
    Alphabetic,

    /// Numbers and floating points.
    Numeric,

    /// Symbols
    Symbolic,

    /// String characters contained in quotes.
    String,
};

/// Change tokenization state 
/// 
/// # States
/// 
/// digits -> Numeric
/// 
/// alphabetic -> Alphabetic
/// 
/// " -> String
/// 
/// other -> Symbolic
/// 
/// # Arguments
/// * `gpa` - General purpose allocator.
/// * `current_char` - The current character in the buffer.
/// * `state` - A reference to the state object that it will be changing.
/// * `buffer` - The buffer of tokens
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

/// Pushes a token into a package.
/// 
/// Matches possible literal or pushes as an identifier.
/// 
/// # Arguments
/// * `gpa` - General purpose allocator
/// * `package` - The package to push the token to.
/// * `buffer` - The current buffer containing the token.
/// * `line` - (optional) The line that is being parsed.
/// * `column_start` | `column_end` - The start and end columns of the token.
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

/// Pushes a numeric token into a package.
/// 
/// Uses the numeric state to parse the buffer into its literal value.
/// 
/// # Arguments
/// * `num_state` - The numeric state of the tokenizer.
/// * `package` - The package that the token will be pushed to.
/// * `buffer` - The current buffer containing the token.
/// * `line` - (optional) The line that is being parsed.
/// * `column_start` | `column_end` - The start and end columns of the token.
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

        // =<numerics>===========================
        // | Size  | fl point | signed | Result |
        // |-------| ---------| ------ | ------ |
        // | byte  | none     | false  | i8     |
        // | byte  | none     | true   | u8     |
        // | ----- | -------- | ------ | ------ |
        // | short | none     | false  | i16    |
        // | short | none     | true   | u16    |
        // | ----- | -------- | ------ | ------ |
        // | def   | false    | false  | i32    |
        // | def   | false    | true   | u32    |
        // | def   | true     | none   | f32    |
        // | ----- | -------- | ------ | ------ |
        // | long  | false    | false  | i64    |
        // | long  | false    | true   | u64    |
        // | long  | true     | none   | f64    |
        // ======================================
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

/// Result of a state machine call
/// 
/// # States
/// * `Ok` - Everything is fine.
/// * `OutOfDate` - The state machine is out of date and needs to be switched.
const StateResult = enum {
    Ok,

    /// The state machine is out of date and needs to be switched.
    OutOfDate,
};

/// Alphabetical State
/// 
/// Creates a token from all alphabetical characters.
/// 
/// # Arguments
/// * `gpa` - General purpose allocator.
/// * `buffer` - The current buffer containing the token.
/// * `package` - The package to push the token to.
/// * `line` - (optional) The line that is being parsed.
/// * `column_start` | `column_end` - The start and end columns of the token.
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

/// Symbolic State 
/// 
/// Creates a token from all symbols.
/// 
/// # Arguments
/// * `gpa` - General purpose allocator.
/// * `buffer` - The current buffer containing the token.
/// * `package` - The package to push the token to.
/// * `line` - (optional) The line that is being parsed.
/// * `column_start` | `column_end` - The start and end columns of the token.
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

/// Numeric State 
/// 
/// Creates a numeric literal from a buffer of numbers
/// 
/// # Arguments
/// * `gpa` - General purpose allocator.
/// * `state` - The numeric state of the parser.
/// * `buffer` - The current buffer containing the token.
/// * `current` - The current token being parsed.
/// * `package` - The package to push the token to.
/// * `line` - (optional) The line that is being parsed.
/// * `column_start` | `column_end` - The start and end columns of the token.
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

/// Possible sizes of a numeric literal
/// 
/// # States
/// * `Byte` - 8 bit integer.
/// * `Short` - 16 bit integer.
/// * `Default` - 32 bit integer.
/// * `Long` - 64 bit integer
const NumericSize = enum {

    /// 8 bit integer
    Byte,

    /// 16 bit integer
    Short,

    /// 32 bit integer
    Default,

    /// 64 bit integer
    Long,
};


/// The state of the parsed numeric literal.
/// 
/// # Properties
/// * `size` - The size of the created numeric literal.
/// * `floating_point` - If the literal should be parsed as a float/double.
/// * `unsigned` - If the literal is unsigned.
/// * `locked` - If the number is finished and can now only parse modifier characters.
const NumericState = struct {

    /// The size of the created numeric literal.
    size: NumericSize = NumericSize.Default,

    /// If the literal should be parsed as a float/double.
    floating_point: bool = false,

    /// If the literal is unsigned.
    unsigned: bool = false,

    /// If the number is finished and can now only parse modifier characters.
    locked: bool = false,
};

/// String State
/// 
/// Parses all characters bound between two quotes. Includes whitespace.
/// 
/// # Arguments
/// * `gpa` - General purpose allocator.
/// * `state` - The numeric state of the parser.
/// * `buffer` - The current buffer containing the token.
/// * `current` - The current token being parsed.
/// * `package` - The package to push the token to.
/// * `line` - (optional) The line that is being parsed.
/// * `column_start` | `column_end` - The start and end columns of the token.
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

/// Tokenizes a string line.
/// 
/// The tokens in the line can be optionally watermarked with the line of origin.
/// 
/// # Arguments
/// * `gpa` - General purpose allocator.
/// * `string` - The string being parsed.
/// * `line` - (optional) the line that the tokens will be watermarked with.
/// 
/// This uses a Deterministic Finite Automata algorithm. This algorithm treats the parser as a state machine
/// switching states depending on the set of rules for a token.
/// 
/// # Example
/// 
/// ```zig
/// const std = @import("std");
/// const enigma = @import("enigma");
/// 
/// const package = try enigma.tokenization.parsing.tokenize_string(
///     std.heap.page_allocator,
///     "Test! 1, 2, 3",
///     null
/// );
/// 
/// std.debug.print("{f}", .{package});
/// ```
pub fn tokenize_string(
    gpa: std.mem.Allocator, 
    string: []const u8, 
    line: ?usize
) !token.TokenPackage {
    var package = try token.TokenPackage.init(null, gpa);

    // State of the state machine
    var state: TokenizationState = .None;

    // Numeric state
    var num_state: NumericState = .{};

    var buffer = try std.ArrayList(u8).initCapacity(gpa, 128);
    defer buffer.deinit(gpa);

    var idx: usize = 0;
    tokenization_loop: while (idx < string.len) {
        const current = string[idx];

        // Break (non-string) tokens when encountering whitespace.
        if (state != .String and std.ascii.isWhitespace(current)) {
            try push_token(gpa, &package, &buffer, line, 0, 0);
            idx += 1;
            continue: tokenization_loop;
        }

        switch (state) {
            // No State - immediately switch to a state.
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

    // Push any remaining token in the buffer.
    if (state == .Numeric) {
        try push_numeric_token(&num_state, &package, &buffer, line, 0, 0);
    } else {
        try push_token(gpa, &package, &buffer, line, 0, 0);
    }

    return package;
}


pub fn tokenize_file(
    gpa: std.mem.Allocator, 
    file_path: []const u8
) !token.TokenPackage {
    _ = gpa;

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    
}


// UNIT TESTS //

test "general_token_parsing_test" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const alloc_status = gpa.deinit();
        if (alloc_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }

    const allocator = gpa.allocator();
    const package = try tokenize_string(allocator, "Testing 1, 2, 3", null);

    std.debug.print("{f}", .{package});
}