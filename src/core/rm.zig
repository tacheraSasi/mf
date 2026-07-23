const std = @import("std");
const stdio = @import("stdio");
const cmd = @import("../cmd.zig");
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

    if (purge) {
        // SAFETY CHECK: we refuse to delete if repo has uncommitted/unpushed work.
        const status_argv = [_][]const u8{ "git", "-C", projDir, "status", "--porcelain" };
        const status_out = cmd.run(io, allocator, &status_argv) catch |err| switch (err) {
            error.ExitCodeFailure => return error.GitCheckFailed,  // not a repo? abort
            else => return err,
        };
        defer allocator.free(status_out);
        if (status_out.len > 0) {
            try console.printLine("refusing to purge: {s} has uncommitted changes", .{projDir});
            return;
        }
        // TODO: also check for unpushed commits (git log @{u}..HEAD)
        try dir.deleteTree(io, projDir);
    }


    try console.printLine("Project: {s} was removed successfully", .{projDir});
}
