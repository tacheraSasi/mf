const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");
const cmd = @import("../cmd.zig");
const constants = @import("../constants.zig");
const utils = @import("../utils.zig");

pub fn status(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !void {
    var write_buf: [4096]u8 = undefined;
    var read_buf: [4096]u8 = undefined;

    var console: stdio.Console = undefined;
    console.init(io, &write_buf, &read_buf);
    const existing_manifest_data = try manifest.parseManifestFile(io, allocator, dir);
    console.printLine("{s}",.{statusString(allocator, existing_manifest_data)});
}

fn statusString(allocator: std.mem.Allocator, projects: []manifest.Project) ![]u8 {
    var buf: std.Io.Writer.Allocating = .init(allocator);
    defer buf.deinit();

    try buf.writer.print("mf manifest: {d} project(s)\n", .{projects.len});
    for (projects) |p| {
        try buf.writer.print("  {s} -> {s}\n", .{ p.dir, p.git });
    }

    // dupe so the returned slice outlives `buf.deinit()`; caller must free it.
    return try allocator.dupe(u8, buf.written());
}
