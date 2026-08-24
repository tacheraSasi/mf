const std = @import("std");

const cmd = @import("cmd.zig");

// returns the git url of a project dir or an error
pub fn GetGitUrl(io: std.Io, allocator: std.mem.Allocator, entry_name: []const u8) ![]const u8 {
    // git runs from process cwd, which IS the scanned dir (opened on ".").
    // So entry.name is a valid relative path for `git -C`.
    const argv = [_][]const u8{ "git", "-C", entry_name, "remote", "get-url", "origin" };
    const result = cmd.run(io, allocator, &argv) catch |err| switch (err) {
        error.ExitCodeFailure => {
            return err;
        },
        else => return err,
    };
    // defer allocator.free(result); // caller owns stdout (see cmd.zig)
    return result;
}

/// performs a git clone in the process cwd
pub fn GitClone(io: std.Io, allocator: std.mem.Allocator, entry_name: []const u8) ![]const u8 {
    // git runs from process cwd, which IS the scanned dir (opened on ".").
    // So entry.name is a valid relative path for `git -C`.
    const argv = [_][]const u8{ "git", "-C", entry_name, "remote", "get-url", "origin" };
    const result = cmd.run(io, allocator, &argv) catch |err| switch (err) {
        error.ExitCodeFailure => {
            return err;
        },
        else => return err,
    };
    // defer allocator.free(result); // caller owns stdout (see cmd.zig)
    return result;
}
