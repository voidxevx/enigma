//! # Zig Core
//! 4/22/2026 - Nyx
//! 
//! Core global objects

const std = @import("std");

/// Global allocator
/// 
/// Since sending an allocator across the ffi is messy it is 
/// moved into a global scope. In most cases that don't involve the 
/// ffi the allocator will be passed as usual but still referencing the global
/// allocator
pub const allocator: std.mem.Allocator = std.heap.page_allocator;
