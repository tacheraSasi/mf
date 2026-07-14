const std = @import("std");
const cmd = @import("cmd.zig");
const manifest = @import("manifest.zig");
const help = @import("help.zig");
const args_parser = @import("args.zig").ArgsParser;
const VERSION = 1;

const Io = std.Io;

const BASE = "/Users/mac/tach/zig";

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    // const parser = args_parser.parse(args) catch {
    //     std.debug.print("{s}",help.HelpText()); // for now i assume any error will only be invalid flag or subcommand
    // };
    const parser = try args_parser.parse(args);

    const base = BASE;
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, base, .{ .iterate = true });
    defer dir.close(io);

    const cliFlags = parser.cli_flags;
    switch (cliFlags.subcommand) {
        .scan => try scan(io, allocator, dir),
        .none => std.debug.print("usage: mf <scan|clone|status|rm|add> [options]\n", .{}),
        else => std.debug.print("not implemented yet\n", .{}),
    }
}

/// this function create a file only if it does not exist other wise it return the actual file itself
pub fn createFileIfNotExist(io: Io, cwd: Io.Dir, sub_path: []const u8) !Io.File {
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

/// scans a dir and creates the manifest file
/// if manifest already existing we only add the new dirs that werent
/// included in the manifest, we dont delete other dirs/projects in the manifest
/// even if they dont exist locally
pub fn scan(io: Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !void {
    const sub_path = try std.fs.path.join(allocator, &.{ BASE, manifest.FILE_NAME });
    defer allocator.free(sub_path);

    const manifestFile = try createFileIfNotExist(io, dir, sub_path);
    defer manifestFile.close(io);

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
        const repo_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ BASE, entry.name });
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
        std.debug.print("dir: {s}, git: {s}\n", .{ entry.name, result });
        _ = try manifest.appendToManifestFile(io,allocator,dir,proj,existing_manifest_data);
    }

    std.debug.print("Dooooneeeeeeeeeeeeeeee\n", .{});
}
