const std = @import("std");
const global = @import("global.zig");
const cmd = @import("cmd.zig");
const Io = std.Io;

const mf = @import("mf");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const base = "/Users/mac/tach/zig";
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, base, .{ .iterate = true });
    defer dir.close(io);

    // `iterate` yields only direct children (one level).
    // `walk` would recurse into every subdirectory.
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .directory) continue;

        // git must run inside the repo; use `-C <abspath>` since the process
        // cwd is not `base`.
        const repo_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ base, entry.name });
        defer allocator.free(repo_path);

        const argv = [_][]const u8{ "git", "-C", repo_path, "remote", "get-url", "origin" };
        const result = try cmd.run(io, allocator, &argv);
        defer allocator.free(result); // caller owns stdout (see cmd.zig)

        std.debug.print("dir: {s}, git: {s}\n", .{ entry.name, result });
    }
}
