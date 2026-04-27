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

    pub fn format(self: *const VirtualMachine, writer: *std.io.Writer) std.Io.Writer.Error!void {
        try writer.print("[VM]\n{f}{f}", .{self.stack, self.heap});
        try writer.print("[PRIMARY-REGISTERS]\n\tr1: {d}\n\tr2: {d}\n\tr3: {d}\n\tr4: {d}\n\tr5: {d}\n\tr6: {d}\n\tr7: {d}\n\tr8: {d}\n", .{
            self.registers.r1.raw.usize, self.registers.r2.raw.usize, self.registers.r3.raw.usize, self.registers.r4.raw.usize,
            self.registers.r5.raw.usize, self.registers.r6.raw.usize, self.registers.r7.raw.usize, self.registers.r5.raw.usize,
        });
        try writer.print("[SMALL-REGISTERS]\n\tsr1: {d}\n\tsr2: {d}\n\tsr3: {d}\n\tsr4: {d}\n", .{
            self.registers.sr1.raw.u8, self.registers.sr2.raw.u8, self.registers.sr3.raw.u8, self.registers.sr4.raw.u8,
        });
        try writer.print("[LARGE-REGISTERS]\n\tlr1: {d}\n\tlr2: {d}\n", .{
            self.registers.lr1.raw.u128, self.registers.lr2.raw.u128,
        });
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

    vm.stack.push(&[_]u8{'h', 'e', 'l', 'l', 'o'}) catch unreachable;

    const t: i32 = 45;
    vm.registers.r1.mov_unsized(std.mem.asBytes(&t)) catch unreachable;
    std.debug.assert(vm.registers.r1.raw.i32 == 45);

    std.debug.print("{f}", .{vm});
    
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