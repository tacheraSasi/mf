const std = @import("std");

/// runs a shell command i ignore the errors for now
pub fn run(io: std.Io, allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
    });

    defer allocator.free(result.stderr);
    // result.stdout is returned; caller owns it and must free it.
    return result.stdout;
}
