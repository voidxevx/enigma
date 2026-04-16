const std = @import("std");
const enigma = @import("enigma");

pub fn main() !void {
    var my_node: enigma.nodes.TestNode = enigma.nodes.TestNode {};
    
    const ambi = my_node.node();
    ambi.test_print();
}