const std = @import("std");
const global = @import("global.zig");
const cmd = @import("cmd.zig");
const Io = std.Io;

const mf = @import("mf");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, "/Users/mac/tach/zig", .{ .iterate = true });
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        if (entry.kind == .file) {
            continue;
        }
        const argv = [_] []const u8{"git","remote","get-url","origin"};
        const result = try cmd.run(io,allocator,&argv);
        std.debug.print("path: {s}, git: {s}\n", .{ entry.path, result });
    }
}
