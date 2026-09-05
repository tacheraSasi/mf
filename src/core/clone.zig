const std = @import("std");

const stdio = @import("stdio");

const git = @import("../git.zig");
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
        // skip cloning if the project dir already exists on disk
        const existing = dir.openDir(io, proj.dir, .{}) catch |err| switch (err) {
            error.FileNotFound => null,
            else => return err,
        };
        if (existing) |d| {
            d.close(io);
            try console.printLine("skipping {s}, already exists", .{proj.dir});
            continue;
        }
        try git.GitClone(io, allocator, ".", proj, console);
    }

    // read the each proj.git
    // clone the projects one by one using the proj.git
    // stream the git output while doing so
    try console.printLine("cloning the entire project dir, each repo one by one", .{});
}
