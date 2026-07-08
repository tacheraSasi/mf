const std = @import("std");
const global = @import("global.zig");
const Io = std.Io;

const mf = @import("mf");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, "/Users/mac/work/akili/erp/backend/docs/", .{ .iterate = true });
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        if (std.mem.eql(u8, @tagName(entry.kind), "file")) {
            continue;
        }
        std.debug.print("path: {s}, kind: {s}\n", .{ entry.path, @tagName(entry.kind) });
    }
}
