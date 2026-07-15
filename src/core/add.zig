const std = @import("std");
const stdio = @import("stdio");
const cmd = @import("../cmd.zig");
const scan = @import("scan.zig");
const constants = @import("../constants.zig");

/// adds a new project
/// clones the repo into BASE then adds the dir and git url to the manifest
/// mf add https://github/.....
pub fn Add(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, git_url: []const u8, console: *stdio.Console) !void {
    // Clone into BASE regardless of the process cwd. `git -C <path> clone`
    // makes git cd into <path> before cloning, so the repo lands in
    // BASE/<repo-name> instead of the caller's cwd.
    try console.print("Cloning the remote repo...\n", .{});
    const argv = [_][]const u8{ "git", "-C", constants.BASE, "clone", git_url };
    _ = cmd.run(io, allocator, &argv) catch |err| switch (err) {
        error.ExitCodeFailure => {
            try console.print("Failed to clone the repo\n", .{});
            return error.CloneFailed;
        },
        else => return err,
    };

    // after adding i just rescan the entire dir for now
    try scan.Scan(io, allocator, dir, console);
}
