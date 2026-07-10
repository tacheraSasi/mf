const std = @import("std");
const global = @import("global.zig");
const cmd = @import("cmd.zig");
const Io = std.Io;

const manifest = @import("data/manifest.zig");

const mf = @import("mf");


pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const base = "/Users/mac/tach/zig";
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, base, .{ .iterate = true });
    defer dir.close(io);

    const sub_path = try std.fs.path.join(allocator, &.{ base, manifest.FILE_NAME });
    defer allocator.free(sub_path);

    const manifestFile = try createFileIfNotExist(io, dir, sub_path);
    defer manifestFile.close(io);

    // start empty for now
    var projects: std.ArrayList(manifest.Project) = .empty;
    defer projects.deinit(allocator);

    // `iterate` yields only direct children (one level).
    // `walk` would recurse into every subdirectory.
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .directory) continue;

        // git must run inside the repo; use `-C <abspath>` since the process
        // cwd is not `base`.
        const repo_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ base, entry.name });
        defer allocator.free(repo_path);

        const argv = [_][]const u8{ "git", "-C", repo_path, "remote", "get-url", "origin" };
        const result = cmd.run(io, allocator, &argv) catch |err| switch (err) {
            error.ExitCodeFailure => {
                continue; // we silently skip the dir wthout a repo
            },
            else => return err,
        };
        // defer allocator.free(result); // caller owns stdout (see cmd.zig)

        const proj: manifest.Project = .{
            .dir = try allocator.dupe(u8, entry.name), // here i dupe so that proj.dir owns its own memory nstead of aliasing the iterator's internal buffer.
            .git = result,
        };

        try projects.append(allocator, proj);

        std.debug.print("dir: {s}, git: {s}\n", .{ entry.name, result });
    }

    const manifestData: manifest.Manifest = .{
        .version = 1,
        .projects = projects.items,
    };

    var buf: std.Io.Writer.Allocating = .init(allocator);
    defer buf.deinit();

    try buf.writer.print("{f}", .{std.json.fmt(manifestData, .{})});
    const json_data = buf.written();

    try cwd.writeFile(io, .{
        .data = json_data,
        .sub_path = sub_path,
    });

    std.debug.print("Dooooneeeeeeeeeeeeeeee\n", .{});

    defer {
        for (projects.items) |p| {
            allocator.free(p.dir);
            allocator.free(p.git);
        }
    }
}

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
