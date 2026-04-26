//! Reference Counting
//! 4/25/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const core = @import("core.zig");
// ----- INCLUDEs

/// Reference Counted 
/// 
/// Smart pointer similar to Rust's Rc or C++'s shared_ptr. 
/// Counts the amount of times the object has been referenced 
/// that way once nothing is using it, it will deallocate.
/// 
/// Because of the way zig functions, a reference must be manually dropped
/// in order for the count to decrement.
/// 
/// When passing a Ref into a function it should always match this pattern:
/// ```
/// fn my_rc_func(val: Rc(MyType).Ref) void {
///     defer val.drop(); // Should be the first thing done
/// }
/// ```
/// And when calling said functions:
/// ```
/// // Always clone the value
/// my_rc_func(my_rc.clone());
/// ```
pub fn Rc(comptime T: type) type {
    return struct {
        const Self = @This();

        /// The value being pointed to.
        val: T,

        /// The count of references.
        count: usize,

        /// A reference to a smart pointer.
        /// No variable should directly store the created Rc
        /// instead multiple Refs are created and cloned 
        /// to track referencing of the pointer.
        pub const Ref = struct {
            ptr: *Self,

            /// Clones the reference creating another reference to the same pointer.
            /// This reference MUST be dropped at some point.
            pub fn clone(self: *const Ref) Ref {
                self.ptr.inc();
                return .{
                    .ptr = self.ptr,
                };
            }

            /// Drops the reference decrementing the count and possible deallocating the data.
            pub fn drop(self: *const Ref) void {
                self.ptr.dec();
            }

            /// Gets a mutable reference to the smart pointers data.
            pub fn mut(self: Ref) *T {
                return &self.ptr.val;
            }

            /// Dereferences the value cloning it.
            pub fn deref(self: Ref) T {
                return self.ptr.val;
            }
        };

        /// Creates a new reference counted value returning the first Ref.
        pub fn new() !Ref {
            const rc = try core.allocator.create(Self);
            rc.*.count = 1;

            return .{
                .ptr = rc,
            };
        }

        fn inc(self: *Self) void {
            self.count += 1;
        }

        fn dec(self: *Self) void {
            self.count -= 1;
            if (self.count <= 0) {
                core.allocator.destroy(self);
            }
        }
    };
}