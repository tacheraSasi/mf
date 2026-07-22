const std = @import("std");
const stdio = @import("stdio");

/// Initializes the workspace by creating an empty manifest file `mf.manifest.json`
pub fn Init(io: std.Io, dir: std.Io.Dir, sub_path: []const u8, console: *stdio.Console) !void {
    var file = dir.createFile(io, sub_path, .{ .read = true, .exclusive = true }) catch |err| switch (err) {
        error.PathAlreadyExists => {
            try console.printLine("The mf workspace is already initialized", .{});
            return;
        },
        else => return err,
    };
    defer file.close(io);
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const path_len = try file.realPath(io, &path_buf);
    const file_path = path_buf[0..path_len];
    try console.printLine("Workspace initialized successfully yeey.\n created {s}", .{file_path});
}
