const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");

pub fn Rm(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8, console: *stdio.Console) !void {
    manifest.removeFromManifestFile(io, allocator, dir, projDir, null) catch |err| switch (err) {
        error.ProjectNotFound => {
            try console.printLine("The project {s} does not exist in the manifest file. Run mf scan to include it.", .{projDir});
            return;
        },
        else => return err,
    };

    try console.printLine("Project: {s} was removed from mf manifest successfully", .{projDir});
}
