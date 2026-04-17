const std = @import("std");

pub fn open_stdout() *std.io.Writer {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    return &stdout_writer.interface;
}

const TokenizationError = error {

};