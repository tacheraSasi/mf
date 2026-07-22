const std = @import("std");
const stdio = @import("stdio");

/// Initializes the workspace by creating an empty manifest file `mf.manifest.json`
pub fn Init(io: std.Io, dir: std.Io.Dir, sub_path: []const u8, console: *stdio.Console) !void {
    dir.createFile(io, sub_path, .{ .read = true, .exclusive = true }) catch |err| switch (err) {
        error.PathAlreadyExists => {
            try console.printLine("The mf workspace is already initialized", .{});
            return;
        },
        else => return err,
    };
    try console.printLine("Workspace initialized successfully yeey.", .{});
}
