const std = @import("std");
const stdio = @import("stdio");
const cmd = @import("../cmd.zig");
const manifest = @import("../manifest.zig");

/// removes the project from the manifest
/// if the purge flag is passed, this will also delete the
/// local dir from the disk
///
/// Returns `error.ProjectNotFound` if the project isn't tracked, or
/// `error.PurgeRefused` if `--purge` was requested but the repo has
/// uncommitted changes. `main` maps these to messages + exit codes (#38).
pub fn Rm(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8, purge: bool, console: *stdio.Console) !void {
    // ProjectNotFound propagates to the caller (see main).
    try manifest.removeFromManifestFile(io, allocator, dir, projDir, null);

    if (purge) {
        // SAFETY CHECK: we refuse to delete if repo has uncommitted/unpushed work.
        const status_argv = [_][]const u8{ "git", "-C", projDir, "status", "--porcelain" };
        const status_out = cmd.run(io, allocator, &status_argv) catch |err| switch (err) {
            error.ExitCodeFailure => return error.GitCheckFailed, // not a repo? abort
            else => return err,
        };
        defer allocator.free(status_out);
        if (status_out.len > 0) {
            return error.PurgeRefused;
        }
        // TODO: also check for unpushed commits (git log @{u}..HEAD)
        try dir.deleteTree(io, projDir);
    }

    try console.printLine("Project: {s} was removed successfully", .{projDir});
}
