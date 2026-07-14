const std = @import("std");


/// this function create a file only if it does not exist other wise it return the actual file itself
pub fn createFileIfNotExist(io: std.Io, cwd: std.Io.Dir, sub_path: []const u8) !std.Io.File {
    return cwd.createFile(io, sub_path, .{
        .read = true,
        .exclusive = true,
    }) catch |err| switch (err) {
        error.PathAlreadyExists => {
            return cwd.openFile(io, sub_path, .{
                .mode = .read_only,
            });
        },
        else => return err,
    };
}