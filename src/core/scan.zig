const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");
const cmd = @import("../cmd.zig");
const constants = @import("../constants.zig");
const utils = @import("../utils.zig");


/// scans a dir and creates the manifest file
/// if manifest already existing it only add the new dirs that werent
/// included in the manifest, it wont delete other dirs/projects in the manifest
/// even if they dont exist locally
pub fn Scan(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !void {
    const sub_path = try std.fs.path.join(allocator, &.{ constants.BASE, manifest.FILE_NAME });
    defer allocator.free(sub_path);

    const manifestFile = try utils.createFileIfNotExist(io, dir, sub_path);
    defer manifestFile.close(io);

    // start empty for now
    var projects: std.ArrayList(manifest.Project) = .empty;
    defer projects.deinit(allocator);

    const existing_manifest_data = try manifest.parseManifestFile(io, allocator, dir);
    // `existing_manifest_data.projects` is a []Project allocated by
    // parseManifestFile. The .dir/.git strings inside are freed by the
    // block below (via the ArrayList copies); this frees the struct array
    // itself to avoid leaking it.
    defer {
        if (existing_manifest_data.projects.len > 0) {
            allocator.free(existing_manifest_data.projects);
        }
    }

    // seeding the existing manifest file data
    for (existing_manifest_data.projects) |existing| {
        try projects.append(allocator, existing);
    }

    // `iterate` yields only direct children (one level).
    // `walk` would recurse into every subdirectory.
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .directory) continue;
        var already_listed = false;

        // i will move this to a hashmap but for now
        // this will work
        for (existing_manifest_data.projects) |existing| {
            if (std.mem.eql(u8, existing.dir, entry.name)) {
                already_listed = true;
                break;
            }
        }
        if (already_listed) continue;

        // git must run inside the repo; use `-C <abspath>` since the process
        // cwd is not `base`.
        const repo_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ constants.BASE, entry.name });
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
        .version = constants.VERSION,
        .projects = projects.items,
    };

    var buf: std.Io.Writer.Allocating = .init(allocator);
    defer buf.deinit();

    try buf.writer.print("{f}", .{std.json.fmt(manifestData, .{ .whitespace = .indent_2 })});
    const json_data = buf.written();

    try dir.writeFile(io, .{
        .data = json_data,
        .sub_path = sub_path,
    });

    std.debug.print("Dooooneeeeeeeeeeeeeeee\n", .{});

    defer {
        for (projects.items) |p| {
            // std.debug.print("freeing dir: {s}\n", .{p.dir});
            allocator.free(p.dir);
            allocator.free(p.git);
        }
    }
}
