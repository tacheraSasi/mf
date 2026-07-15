const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");
const cmd = @import("../cmd.zig");
const constants = @import("../constants.zig");
const utils = @import("../utils.zig");

pub fn Status(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, console: *stdio.Console) !void {
    const existing_manifest_data = try manifest.parseManifestFile(io, allocator, dir);
    // `parseManifestFile` dupes every .dir/.git + the []Project array into
    // `allocator`; we own all of it and must free it before returning.
    // Order matters: free the strings first (looping the array), then the
    // array itself. The empty-manifest case returns a static `&.{}` that
    // must NOT be freed, hence the length check.
    // thiss  took me a long time to fix haha
    defer {
        for (existing_manifest_data.projects) |p| {
            allocator.free(p.dir);
            allocator.free(p.git);
        }
        if (existing_manifest_data.projects.len > 0) {
            allocator.free(existing_manifest_data.projects);
        }
    }

    const s = try statusString(allocator, existing_manifest_data.projects);
    defer allocator.free(s);

    try console.printLine("{s}", .{s});
}

fn statusString(allocator: std.mem.Allocator, projects: []manifest.Project) ![]u8 {
    var buf: std.Io.Writer.Allocating = .init(allocator);
    defer buf.deinit();

    if (projects.len > 1) {
        try buf.writer.print("mf manifest: {d} projects\n", .{projects.len});
    } else {
        try buf.writer.print("mf manifest: {d} project\n", .{projects.len});
    }

    // for (projects) |p| {
    //     try buf.writer.print("  {s} -> {s}\n", .{ p.dir, p.git });
    // }

    // dupe so the returned slice outlives `buf.deinit()`; caller must free it.
    return try allocator.dupe(u8, buf.written());
}
