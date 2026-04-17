//! # Token
//! 4/16/2026 - Nyx
//! 
//! Tokens are a single word, value, symbol, etc in a file.
//! Files are parsed into tokens to create a simplified version of the 
//! source file that can more easily be converted into a AST.


// INCUDES ----- 
const std = @import("std");
const ObjectLiteral = @import("../literals.zig").ObjectLiteral;
// ----- INCLUDES

/// The type of the token.
/// 
/// # Variants
/// * `Identifier` - A string value representing any token that wasn't an object literal.
/// * `Literal` - A token that stores an object literal e.i int, float, string, etc.
/// 
/// Implements format method.
/// 
/// # Examples
/// 
/// Identifier Token
/// 
/// ```zig
/// const token = @import("enigma").token;
/// 
/// const token_type = token.TokenType {
///     .identifier = "Main"
/// };
/// ```
/// 
/// Literal Token
/// 
/// ```zig
/// const token = @import("enigma").token;
/// const literals = @import("enigma").literals;
/// 
/// const token_type = token.TokenType {
///     .literal = literals.ObjectLiteral {
///         .int = 45
///     }
/// };
/// ``` 
pub const TokenType = union(enum) {
    /// A string value representing any token that wasn't an object literal.
    identifier: []const u8,

    /// A token that stores an object literal e.i int, float, string, etc.
    literal: ObjectLiteral,

    /// Format Implementation.
    pub fn format(
        self: TokenType,
        writer: anytype,
    ) !void {
        switch (self) {
            .identifier => |ident| {
                try writer.print("{s}", .{ident});
            },

            .literal => |lit| {
                try writer.print("{f}", .{lit});
            }
        }
    }
};


/// A token with tracing data
/// 
/// # Properties
/// * `token_type` - The type of the token.
/// * `line` - (optional) The line within the file the token originates from.
/// * `column_start` & `column_end` - (optional) The start and end columns that the token was sourced from. 
/// 
/// Implements the format method.
/// 
/// # Example
/// 
/// ```zig
/// const token = @import("enigma").token;
/// 
/// const token = token.Token {
///     .token_type = .{
///         .identifier = "Main"
///     },
///     .line = 7,
///     .column_start = null,
///     .column_end = null,
/// };
/// ```
pub const Token = struct {
    /// The type of the token.
    token_type: TokenType,

    /// The line within the file the token originates from.
    line: ?usize = null,

    /// The start column that the token was sourced from. 
    column_start: ?usize = null,

    /// The end column that the token was sourced from.
    column_end: ?usize = null,

    /// Format Implementation
    pub fn format(
        self: Token,
        writer: anytype
    ) !void {
        try writer.print("{f}", .{self.token_type});
    }
};


// TOKEN PACKAGES //

/// Token Package
/// 
/// An array of tokens that can be iterated over, split, merged, and debugged.
/// Token packages automatically handle the memory of the tokens stored.
/// 
/// # Properties
/// * `tokens` - The buffer of tokens. This is a buffer meaning there is buffered space at the end of the array.
/// * `token_count` - The actual count of tokens in the package.
/// * `token_capacity` - The actual size of the array including buffer space.
/// * `allocator` - The allocator used to handle memory management.
/// * `origin` - (optional) The file that the package was sourced from.
/// 
/// # Example
/// 
/// ```zig
/// const std = @import("std");
/// const enigma = @import("enigma");
/// 
/// var package = try enigma.token.TokenPackage.init(null, std.heap.page_allocator);
/// defer package.deinit();
/// 
/// package.add_token(enigma.token.Token {
///     .token_type = .{ .identifier = "Test" }
/// })
/// ```
/// 
/// Implements the format method 
pub const TokenPackage = struct {
    const Self = TokenPackage;

    /// The buffer of tokens. This is a buffer meaning there is buffered space at the end of the array.
    tokens: []Token,

    /// The actual count of tokens in the package.
    token_count: usize,

    /// The actual size of the array including buffer space.
    token_capacity: usize,

    /// The allocator used to handle memory management.
    allocator: std.mem.Allocator,

    /// The file that the package was sourced from.
    origin: ?[]const u8,

    /// Creates a new token package.
    pub fn init(
        origin: ?[]const u8, 
        allocator: std.mem.Allocator
    ) !Self {
        const capacity = 2;
        const tokens = try allocator.alloc(Token, capacity);

        return TokenPackage {
            .tokens = tokens,
            .token_count = 0,
            .token_capacity = capacity,
            .allocator = allocator,
            .origin = origin,
        };
    }

    /// Deletes the buffer of tokens
    pub fn deinit(self: Self) void {
        self.allocator.free(self.tokens);
    }

    /// Adds a new token to the end of the array.
    /// 
    /// This will automatically grow the buffer as needed.
    /// When reallocated the resulting capacity is doubled.
    pub fn add_token(self: *Self, token: Token) !void {
        if (self.token_count >= self.token_capacity) {
            self.token_capacity *= 2;
            self.tokens = try self.allocator.realloc(self.tokens, self.token_capacity);
        }

        self.tokens[self.token_count] = token;
        self.token_count += 1;
    }

    /// Merges a package into an existing package.
    /// 
    /// The memory of the merged package is copied into the calling package and 
    /// then deinit is called on the package.
    /// 
    /// The resulting capacity of the buffer is the sum of both packages.
    pub fn merge(
        self: *Self, 
        other: Self
    ) !void {
        const new_capacity = self.token_capacity + other.token_capacity;
        self.tokens = try self.allocator.realloc(self.tokens, new_capacity);

        @memcpy(self.tokens[self.token_count..(other.token_count + self.token_count)], other.tokens);
        self.token_count += other.token_count;
        self.token_capacity = new_capacity;
        other.deinit();
    }

    /// Condenses the buffer removing any buffer space.
    /// 
    /// This should be called before iterating or splitting the package.
    pub inline fn condense(self: *Self) !void {
        if (self.token_count != self.token_capacity) {
            self.tokens = try self.allocator.realloc(self.tokens, self.token_count);
            self.token_capacity = self.token_count;
        }
    }


    /// Splits the package about a point creating two new package from left and right of the break point.
    /// Neither created package will contain the token at the break point.
    /// 
    /// The resulting packages contain full ownership copies of the original data. 
    /// The package alongside the data calling this function will automatically be deallocated at the end of method.
    pub fn split(
        self: *Self, 
        point: usize
    ) !struct {
        Self, 
        Self
    } {
        // the package is de-initialized at the end of the method.
        defer self.deinit();
        try self.condense();

        // Allocate new buffers for left and right packages.
        const left_size = point;
        const right_size = self.token_count - (point + 1);
        const left_buffer = try self.allocator.alloc(Token, left_size);
        const right_buffer = try self.allocator.alloc(Token, right_size);

        // Copy the data from the original package into the buffers.
        @memcpy(left_buffer, self.tokens[0..point]);
        @memcpy(right_buffer, self.tokens[point + 1..self.token_count]);

        return .{
            Self {
                .tokens = left_buffer,
                .token_count = left_size,
                .token_capacity = left_size,
                .allocator = self.allocator,
                .origin = self.origin, 
            },

            Self {
                .tokens = right_buffer,
                .token_count = right_size,
                .token_capacity = right_size,
                .allocator = self.allocator,
                .origin = self.origin, 
            }
        };
    }

    /// Format prints the entire package with optional highlighting for a specific token or line.
    pub fn format_highlighted(
        self: Self,
        writer: anytype,
        highlighted_token: ?usize,
    ) !void {
        if (self.origin) |origin| {
            try writer.print("Package: {s}\n", .{origin});
        } else {
            try writer.print("Package\n", .{});
        }

        var current_line: ?usize = null;
        var first_column: usize = 0;
        var last_column: usize = 0;

        for (0..self.token_count) |idx| {
            const current_token = &self.tokens[idx];
            last_column = current_token.column_end orelse 0;
            if (current_line == null) {
                try writer.print("\t[{d}]", .{current_token.line orelse 0});
                current_line = current_token.line orelse 0;
                first_column = current_token.column_start orelse 0;
            }

            if (current_line.? != current_token.line orelse 0) {
                try writer.print("\t{d}:{d}\n\t[{d}]", .{first_column, last_column, current_token.line orelse 0});
                current_line = current_token.line orelse 0;
                first_column = current_token.column_start orelse 0;
            }

            if (highlighted_token != null and idx == highlighted_token.?) {
                try writer.print(" \x1b[4;31m{f}\x1b[0m", .{current_token});
            } else {
                try writer.print(" {f}", .{current_token});
            }
        }
        
        try writer.print("\t{d}:{d}\n", .{first_column, last_column});
    }

    /// Implementation of the format method.
    pub fn format(
        self: Self,
        writer: anytype
    ) !void {
        try self.format_highlighted(writer, null);
    }
};

// UNIT TESTS //

test "token_package_general_test" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const alloc_status = gpa.deinit();
        if (alloc_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }

    const allocator = gpa.allocator();
    var package = try TokenPackage.init(null, allocator);
    defer package.deinit();

    for (0..50) |_| {
        try package.add_token(.{ .token_type = .{ .identifier = "A" } });
    }
}

test "token_package_splitting_test" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const alloc_status = gpa.deinit();
        if (alloc_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }

    const allocator = gpa.allocator();
    var package = try TokenPackage.init(null, allocator);

    for (0..50) |_| {
        try package.add_token(.{ .token_type = .{ .identifier = "A" } });
    }    


    const l_package, const r_package = try package.split(15);
    defer {
        l_package.deinit();
        r_package.deinit();
    }
}