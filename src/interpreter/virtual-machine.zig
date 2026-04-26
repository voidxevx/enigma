//! Virtual Machine
//! 4/25/2026 - Nyx

// INCLUDES -----
const std = @import("std");
const mem = @import("memory/mod.zig");
// ----- INCLUDES

pub const VirtualMachine = struct {
    stack: mem.stack.Stack,
    heap: mem.heap.HeapMemory,

    registers: struct {
        // Primary Registers
        r1: mem.register.PrimaryRegister = .empty(),
        r2: mem.register.PrimaryRegister = .empty(),
        r3: mem.register.PrimaryRegister = .empty(),
        r4: mem.register.PrimaryRegister = .empty(),
        r5: mem.register.PrimaryRegister = .empty(),
        r6: mem.register.PrimaryRegister = .empty(),
        r7: mem.register.PrimaryRegister = .empty(),
        r8: mem.register.PrimaryRegister = .empty(),

        // Large Registers
        lr1: mem.register.LargeRegister = .empty(),
        lr2: mem.register.LargeRegister = .empty(),

        // Small Registers
        sr1: mem.register.SmallRegister = .empty(),    
        sr2: mem.register.SmallRegister = .empty(),    
        sr3: mem.register.SmallRegister = .empty(),    
        sr4: mem.register.SmallRegister = .empty(),    
    } = .{},

    pub fn init(gpa: std.mem.Allocator) !VirtualMachine {
        return .{
            .stack = try .init(gpa),
            .heap = try .init(gpa),
        };
    }
};




const core = @import("../core.zig");
const Rc = @import("../rc.zig").Rc;

fn ref_test(val: Rc(i32).Ref) void {
    defer val.drop();

    //...
}

pub export fn test_vm() void {
    const gpa = std.heap.page_allocator;

    var vm = VirtualMachine.init(gpa) catch unreachable;

    const t: i32 = 45;
    vm.registers.r1.mov_unsized(std.mem.asBytes(&t)) catch unreachable;
    std.debug.assert(vm.registers.r1.raw.i32 == 45);

    const a = 56;
    const b = 23;
    const o = core.cmp(i32, a, b);
    std.debug.print("{d} {f} {d}\n", .{a, o, b});
    if (o.i() & core.Ord.Ge == o.i()) {
        std.debug.print("Greater or Equal!\n", .{});
    }

    var rc = Rc(i32).new() catch unreachable;
    defer rc.drop();

    rc.mut().* = 45;
    std.debug.assert(rc.deref() == 45);

    ref_test(rc.clone());
}