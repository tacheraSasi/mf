const std = @import("std");

const stdio = @import("stdio");

const manifest = @import("../manifest.zig");

/// clones/replicates the entire dir cloning each repo/project as per manifest file
pub fn Clone(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, console: *stdio.Console) !void {
    // get all the projects from the manifest file is the file exists
    const manifest_data = try manifest.parseManifestFile(io, allocator, dir);
    defer {
        if (manifest_data.projects.len > 0) {
            allocator.free(manifest_data.projects);
        }
    }

    defer {
        for (manifest_data.projects) |p| {
            allocator.free(p.dir);
            allocator.free(p.git);
        }
    }

    for (manifest_data.projects) |proj| {
        try console.printLine("cloning {s}...", .{proj.dir});
    }

    // read the each proj.git
    // clone the projects one by one using the proj.git
    // stream the git output while doing so
    try console.printLine("cloning the entire project dir, each repo one by one", .{});
}
