const std = @import("std");
const objects = @import("objects.zig");


pub const HeapSparseSet = struct {
    const DEFAULT_SET_CAPACITY: usize = 16;
    
    gpa: std.mem.Allocator,

    sparse: Set(usize),
    dense: Set(objects.Object),
    unused: Set(objects.IdentifierHash),

    fn Set(comptime T: type) type {
        return struct {
            const Self = @This();

            set: []T,
            size: usize = 0,
            capacity: usize = DEFAULT_SET_CAPACITY,

            fn init(memory: []T) Self {
                return .{
                    .set = memory
                };
            }

            fn deinit(self: *Self, gpa: std.mem.Allocator) void {
                gpa.free(self.set);
            }
        };
    }

    pub fn init(gpa: std.mem.Allocator) !HeapSparseSet {
        const sparse_set = try gpa.alloc(usize, DEFAULT_SET_CAPACITY);
        @memset(sparse_set, std.math.maxInt(usize));

        return .{
            .gpa = gpa,
            .sparse = .init(sparse_set),
            .dense = .init(try gpa.alloc(objects.Object, DEFAULT_SET_CAPACITY)),
            .unused = .init(try gpa.alloc(usize, DEFAULT_SET_CAPACITY)),
        };
    }

    pub fn deinit(self: *HeapSparseSet) void {
        self.sparse.deinit(self.gpa);
        self.dense.deinit(self.gpa);
        self.unused.deinit(self.gpa);
    }

    fn push_unused(self: *HeapSparseSet, id: objects.IdentifierHash) !void {
        if (self.unused.size >= self.unused.capacity) {
            self.*.unused.capacity *= 2;
            self.*.unused.set = try self.gpa.realloc(self.unused.set, self.unused.capacity);
        }

        self.*.unused.set[self.unused.size] = id;
        self.*.unused.size += 1;
    }

    fn pop_unused(self: *HeapSparseSet) ?objects.IdentifierHash {
        if (self.unused.size == 0)
            return null;

        self.*.unused.size -= 1;
        return self.unused.set[self.unused.size];
    }

    pub fn emplace(self: *HeapSparseSet, data: objects.Object) !objects.IdentifierHash {
        const id: objects.IdentifierHash = if (self.pop_unused()) |unused_id|
            unused_id 
        else create_id: {
            if (self.sparse.size >= self.sparse.capacity) {
                self.*.sparse.capacity *= 2;
                self.*.sparse.set = try self.gpa.realloc(self.sparse.set, self.sparse.capacity);
            }

            defer self.*.sparse.size += 1;
            break :create_id self.sparse.size;
        };

        const idx = self.dense.size;
        self.*.sparse.set[id] = idx;
        self.*.dense.set[idx] = data;
        self.*.dense.size += 1;

        return id;        
    }

    pub fn free(self: *HeapSparseSet, id: objects.IdentifierHash) !void {
        const removing_idx = self.sparse.set[id];

        const swapping_idx = self.dense.size - 1;
        const swapping_id = find_swapping_id: {
            var i: usize = 0;
            while (i < self.sparse.size and self.sparse.set[id] != swapping_idx)
                i += 1;
            break :find_swapping_id i;
        };

        self.*.dense.set[removing_idx] = self.dense.set[swapping_idx];
        self.*.sparse.set[swapping_id] = removing_idx;
        self.*.sparse.set[id] = std.math.maxInt(usize);

        self.*.dense.size -= 1;
        try self.push_unused(id);
    }

    pub fn get(self: *const HeapSparseSet, id: objects.IdentifierHash) *const objects.Object {
        return &self.dense.set[self.sparse.set[id]];
    }

    pub fn get_mut(self: *HeapSparseSet, id: objects.IdentifierHash) *objects.Object {
        return &self.dense.set[self.sparse.set[id]];
    }
};