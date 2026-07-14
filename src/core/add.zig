const std = @import("std");
const cmd = @import("../cmd.zig");

/// add a new project
/// clones the repo then adds the dir and git url to the manifest
/// mf add https://github/.....
pub fn Add(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, git_url: []const u8) !void{
    // run git clone command
    const argv = [_][]const u8{ "git", "clone", git_url };
    _ = cmd.run(io, allocator, &argv) catch |err| switch (err) {
        error.ExitCodeFailure => {
            return std.debug.print("Failed to clone the repo",.{});
        },
        else => return err,
    };

    // after clone is done add the project to the manifest file
}