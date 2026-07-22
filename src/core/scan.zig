const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");
const cmd = @import("../cmd.zig");
const utils = @import("../utils.zig");

/// scans a dir and creates the manifest file
/// if manifest already existing it only add the new dirs that werent
/// included in the manifest, it wont delete other dirs/projects in the manifest
/// even if they dont exist locally
pub fn Scan(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, console: *stdio.Console) !void {
    // The manifest file lives at the root of the scanned dir. Since `dir`
    // was opened on "." (process cwd), this is just the filename no BASE join.
    const sub_path = manifest.FILE_NAME;

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

        // git runs from process cwd, which IS the scanned dir (opened on ".").
        // So entry.name is a valid relative path for `git -C`.
        const argv = [_][]const u8{ "git", "-C", entry.name, "remote", "get-url", "origin" };
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

        try console.print("dir: {s}, git: {s}\n", .{ entry.name, result });
    }

    const manifestData: manifest.Manifest = .{
        .version = 1,
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

    try console.print("Dooooneeeeeeeeeeeeeeee\n", .{});

    defer {
        for (projects.items) |p| {
            // try console.print("freeing dir: {s}\n", .{p.dir});
            allocator.free(p.dir);
            allocator.free(p.git);
        }
    }
}
