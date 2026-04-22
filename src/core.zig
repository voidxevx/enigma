const std = @import("std");
pub const allocator: std.mem.Allocator = std.heap.page_allocator;
