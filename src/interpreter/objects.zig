//! # Objects
//! 4/22/2026 - Nyx
//! 
//! An identical Rust implementation can be found at: ./objects.rs

// INCLUDES -----
const std = @import("std");

/// Hashed Identifier
/// 
/// An identifier that was hashed into a smaller sequence to allow for more efficient memory management.
pub const IdentifierHash = usize;

/// Object
/// 
/// An ambiguous object stored by the interpreter.
/// Objects are set up in a special way that lets them be converted 
/// into a ffi compatible raw type and passed between Zig and Rust.
pub const Object = union(Type) {
    byte: i8,
    ubyte: u8,
    short: i16,
    ushort: u16,
    int: i32,
    uint: u32,
    long: i64,
    ulong: u64,

    float: f32,
    double: f64,

    identifier: IdentifierHash,

    pub const Type = enum(u8) {
        byte,
        ubyte,
        short,
        ushort,
        int,
        uint,
        long,
        ulong,

        float,
        double,

        identifier,
    };

    /// Raw extern union of the data
    pub const Raw = extern union {
        byte: i8,
        ubyte: u8,
        short: i16,
        ushort: u16,
        int: i32,
        uint: u32,
        long: i64,
        ulong: u64,

        float: f32,
        double: f64,

        identifier: IdentifierHash,
    };

    /// Raw version of the object packed identically but ffi compatible.
    pub const RawObject = extern struct {
        type: Type,
        raw: Raw,

        pub fn pack(self: RawObject) Object {
            switch (self.type) {
                .byte => return .{ .byte = self.raw.byte },
                .ubyte => return .{ .ubyte = self.raw.ubyte },
                .short => return .{ .short = self.raw.short },
                .ushort => return .{ .ushort = self.raw.ushort },
                .int => return .{ .int = self.raw.int },
                .uint => return .{ .uint = self.raw.uint },
                .long => return .{ .long = self.raw.long },
                .ulong => return .{ .ulong = self.raw.ulong },
                .float => return .{ .float = self.raw.float },
                .double => return .{ .double = self.raw.double },
                .identifier => return .{ .identifier = self.raw.identifier },
            }
        }
    };

    pub const ObjectRef = union(Type) {
        byte: *i8,
        ubyte: *u8,
        short: *i16,
        ushort: *u16,
        int: *i32,
        uint: *u32,
        long: *i64,
        ulong: *u64,

        float: *f32,
        double: *f64,

        identifier: *IdentifierHash,

        pub const RawRef = extern union {
            byte: *i8,
            ubyte: *u8,
            short: *i16,
            ushort: *u16,
            int: *i32,
            uint: *u32,
            long: *i64,
            ulong: *u64,

            float: *f32,
            double: *f64,

            identifier: *IdentifierHash,
        };

        pub const RawObjectRef = extern struct {
            type: Type,
            raw: RawRef,

            pub fn pack(self: RawObjectRef) ObjectRef {
                switch (self.type) {
                    .byte => return .{ .byte = self.raw.byte },
                    .ubyte => return .{ .ubyte = self.raw.ubyte },
                    .short => return .{ .short = self.raw.short },
                    .ushort => return .{ .ushort = self.raw.ushort },
                    .int => return .{ .int = self.raw.int },
                    .uint => return .{ .uint = self.raw.uint },
                    .long => return .{ .long = self.raw.long },
                    .ulong => return .{ .ulong = self.raw.ulong },
                    .float => return .{ .float = self.raw.float },
                    .double => return .{ .double = self.raw.double },
                    .identifier => return .{ .identifier = self.raw.identifier },
                }
            }
        };

        pub fn raw(self: ObjectRef) RawObjectRef {
            switch (self) {
            .byte => |i| return .{ .type = .byte, .raw = .{ .byte = i } },
            .ubyte => |i| return .{ .type = .ubyte, .raw = .{ .ubyte = i } },
            .short => |i| return .{ .type = .short, .raw = .{ .short = i } },
            .ushort => |i| return .{ .type = .ushort, .raw = .{ .ushort = i } },
            .int => |i| return .{ .type = .int, .raw = .{ .int = i } },
            .uint => |i| return .{ .type = .uint, .raw = .{ .uint = i } },
            .long => |i| return .{ .type = .long, .raw = .{ .long = i } },
            .ulong => |i| return .{ .type = .ulong, .raw = .{ .ulong = i } },
            .float => |i| return .{ .type = .float, .raw = .{ .float = i } },
            .double => |i| return .{ .type = .double, .raw = .{ .double = i } },
            .identifier => |i| return .{ .type = .identifier, .raw = .{ .identifier = i } },
        }
        }
    };

    pub fn raw(self: Object) RawObject {
        switch (self) {
            .byte => |i| return .{ .type = .byte, .raw = .{ .byte = i } },
            .ubyte => |i| return .{ .type = .ubyte, .raw = .{ .ubyte = i } },
            .short => |i| return .{ .type = .short, .raw = .{ .short = i } },
            .ushort => |i| return .{ .type = .ushort, .raw = .{ .ushort = i } },
            .int => |i| return .{ .type = .int, .raw = .{ .int = i } },
            .uint => |i| return .{ .type = .uint, .raw = .{ .uint = i } },
            .long => |i| return .{ .type = .long, .raw = .{ .long = i } },
            .ulong => |i| return .{ .type = .ulong, .raw = .{ .ulong = i } },
            .float => |i| return .{ .type = .float, .raw = .{ .float = i } },
            .double => |i| return .{ .type = .double, .raw = .{ .double = i } },
            .identifier => |i| return .{ .type = .identifier, .raw = .{ .identifier = i } },
        }
    }

    pub fn ref(self: *Object) ObjectRef {
        switch (self.*) {
            .byte => return .{ .byte = &self.byte },
            .ubyte => return .{ .ubyte = &self.ubyte },
            .short => return .{ .short = &self.short },
            .ushort => return .{ .ushort = &self.ushort },
            .int => return .{ .int = &self.int },
            .uint => return .{ .uint = &self.uint },
            .long => return .{ .long = &self.long },
            .ulong => return .{ .ulong = &self.ulong },
            .float => return .{ .float = &self.float },
            .double => return .{ .double = &self.double },
            .identifier => return .{ .identifier = &self.identifier },
        }
    }

    pub fn format(self: *const Object, writer: *std.io.Writer) std.Io.Writer.Error!void {
        _ = self;
        try writer.print("LIT", .{});
    }

};