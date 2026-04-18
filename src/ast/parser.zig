//! # Parser
//! 4/18/2026 - Nyx

const std = @import("std");
const lexing = @import("../lexing/tokenization.zig");
const node = @import("node.zig");
const Operator = @import("../operator.zig").Operator;



pub fn parse_tokens(package: *lexing.token.TokenPackage) !node.INode {

    // Denotations:
    // tuples: (usize, usize)
    //           ^idx   ^precedence

    // Null denotation - left unary
    var nud: ?usize = null;
    var nud_op: ?*const Operator = null;

    // Left denotation - binary
    var led: ?struct {usize, usize} = null;
    var led_op: ?*const Operator = null;

    // Right denotation - right unary
    var rid: ?usize = null;
    var rid_op: ?*const Operator = null;

    const last = package.token_count;
    var package_iterator = package.iter();
    var idx: usize = 0;
    while (package_iterator.next()) |token| {
        switch (token.token_type) {
            .operator => |op| {

                // Prefix unary operator / Null denotation operator
                if (idx == 0) {
                    if (op.prefix_binding_power) |pre| {
                        nud = pre;
                        nud_op = op;
                    }
                } 
                
                // Suffix unary operator / right denotation operator
                else if (idx == last) {
                    if (op.suffix_binding_power) |pre| {
                        rid = pre;
                        rid_op = op;
                    }
                } 
                
                // Override current left denotation operator
                else if (led) |led_r| {
                    if (op.infix_binding_power) |pre| {
                        _, const led_pre = led_r;
                        if (pre > led_pre) {
                            led = .{idx, pre};
                            led_op = op;
                        }
                    }
                } 
                
                // Set left denotation binary operator
                else if (op.infix_binding_power) |pre| {
                    led = .{idx, pre};
                    led_op = op;
                }
            },
            else => {}
        }

        idx += 1;
    }

    const nud_precedence: usize = nud orelse 0;
    const rid_precedence: usize = rid orelse 0;
    const led_precedence: usize = if (led) |r_led| r_led.@"1" else 0;

    const greatest: enum {
        None,
        NUD,
        RID,
        LED,
    } = 
    compare_denotation_precedences: {
        if (nud_precedence == 0 and rid_precedence == 0 and led_precedence == 0) {
            break :compare_denotation_precedences .None;
        } else if (nud_precedence > led_precedence and nud_precedence > rid_precedence) {
            break :compare_denotation_precedences .NUD;
        } else if (led_precedence > rid_precedence) {
            break :compare_denotation_precedences .LED;
        } else {
            break :compare_denotation_precedences .RID;
        }
    };


    switch (greatest) {
        .LED => {
            const led_idx, _ = led.?;
            var l_package, var r_package = try package.split(led_idx);
            // For future: compute l and r packages on separate threads        

            const l_node = try parse_tokens(&l_package); 
            const r_node = try parse_tokens(&r_package);

            const symbol: []u8 = try package.allocator.alloc(u8, led_op.?.symbol.len);
            @memmove(symbol, led_op.?.symbol);

            var binary_node: node.BinaryNode = .{
                .symbol = symbol,
                .left_node = l_node,
                .right_node = r_node,
            };
            return binary_node.interface();
        },

        else => {}
    }

    var n = node.NullNode{};
    package.deinit();
    return n.interface();
}