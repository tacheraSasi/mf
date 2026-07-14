const std = @import("std");
pub const FILE_NAME = "mf.manifest.json";

/// struct for the manifest json file structure
pub const Manifest = struct {
    version: u32,
    projects: []Project,
};

/// struct for the project structure
pub const Project = struct {
    dir: []const u8,
    git: []const u8,
};

/// parses an existing manifest file and returns the `Manifest` struct.
///
/// The returned `Manifest` is fully owned by `allocator`: the `projects`
/// slice and every `dir`/`git` string are duped out of the JSON parser's
/// internal arena (which is freed before this function returns) so the
/// caller can free each piece via `allocator.free(...)`.
pub fn parseManifestFile(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !Manifest {
    const json_data = try dir.readFileAlloc(io, FILE_NAME, allocator, .unlimited);
    defer allocator.free(json_data);

    // Empty (or not-yet-written) manifest → no projects. Return a static
    // empty slice; the caller must NOT free it (see conditional free in scan).
    if (json_data.len == 0) {
        return .{ .version = 0, .projects = &.{} };
    }

    const parsed_data = try std.json.parseFromSlice(Manifest, allocator, json_data, .{});
    defer parsed_data.deinit();

    const src_projects = parsed_data.value.projects;

    // Dupe the projects slice + each string into the caller's allocator so
    // the returned Manifest outlives `parsed_data`'s arena.
    const owned_projects = try allocator.alloc(Project, src_projects.len);
    var filled: usize = 0;
    errdefer {
        for (owned_projects[0..filled]) |p| {
            allocator.free(p.dir);
            allocator.free(p.git);
        }
        allocator.free(owned_projects);
    }
    for (src_projects) |src| {
        owned_projects[filled] = .{
            .dir = try allocator.dupe(u8, src.dir),
            .git = try allocator.dupe(u8, src.git),
        };
        filled += 1;
    }

    return .{
        .version = parsed_data.value.version,
        .projects = owned_projects,
    };
}

/// appends a new item to the manifest file
pub fn appendManifest(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !Manifest {
    const existing_manifest_data = try parseManifestFile(io, allocator, dir);
    // `existing_manifest_data.projects` is a []Project allocated by
    // parseManifestFile. The .dir/.git strings inside are freed by the
    // block below (via the ArrayList copies); this frees the struct array
    // itself to avoid leaking it.
    defer {
        if (existing_manifest_data.projects.len > 0) {
            allocator.free(existing_manifest_data.projects);
        }
    }
}
