const std = @import("std");

/// runs a shell command
pub fn run(io:std.Io,allocator: std.mem.Allocator, argv:[_][]const u8) ![]const u8 {
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
    });

    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);

    return result.stdout;
}