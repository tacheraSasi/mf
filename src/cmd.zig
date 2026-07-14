const std = @import("std");

pub const Error = error{ ExitCodeFailure, OutOfMemory };

/// runs a shell command i ignore the errors for now
pub fn run(io: std.Io, allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
    });
    defer allocator.free(result.stderr);
    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };

    if (!ok) {
        //TODO: i will figure out a btter way to handle error here later
        allocator.free(result.stdout);
        return error.ExitCodeFailure;
    }

    // Trim trailing whitespace (commands typically emit a trailing newline).
    // trimRight returns a subslice, so we dupe to give the caller a
    // standalone allocation it can free.
    var end = result.stdout.len;
    while (end > 0) : (end -= 1) {
        const c = result.stdout[end - 1];
        if (c != '\n' and c != '\r' and c != ' ' and c != '\t') break;
    }
    if (end == result.stdout.len) return result.stdout; // nothing to trim here

    const trimmed = try allocator.dupe(u8, result.stdout[0..end]);
    allocator.free(result.stdout);
    return trimmed;
}
