const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");

/// removes the project from the manifest
/// if the purge flag is passed, this will also delete the 
/// local dir from the disk
pub fn Rm(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8,purge:bool, console: *stdio.Console) !void {
    manifest.removeFromManifestFile(io, allocator, dir, projDir, null) catch |err| switch (err) {
        error.ProjectNotFound => {
            try console.printLine("The project {s} does not exist in the manifest file. Run mf scan to include it.", .{projDir});
            return;
        },
        else => return err,
    };

    if(purge){
        try console.printLine("Purging the local dir: {s}", .{projDir});
        try dir.deleteDir(io, projDir);
    }

    try console.printLine("Project: {s} was removed from mf manifest successfully", .{projDir});
}
