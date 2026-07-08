const std = @import("std");
const Io = std.Io;

const mf = @import("mf");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
}
