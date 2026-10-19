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
    const json_data = dir.readFileAlloc(io, FILE_NAME, allocator, .unlimited) catch |err| switch (err) {
        error.FileNotFound => return error.ManifestNotFound,
        else => return err,
    };
    defer allocator.free(json_data);

    // Empty (or not-yet-written) manifest -> no projects. Return a static
    // empty slice; the caller must NOT free it (see conditional free in scan).
    if (json_data.len == 0) {
        return .{ .version = 0, .projects = &.{} };
    }

    // Ignore unknown fields so a manifest written by a newer mf version still
    // loads; `version` can drive explicit migrations later.
    const parsed_data = std.json.parseFromSlice(Manifest, allocator, json_data, .{
        .ignore_unknown_fields = true,
    }) catch |err| switch (err) {
        error.OutOfMemory => return err,
        error.SyntaxError, error.UnexpectedEndOfInput => return error.InvalidManifestSyntax,
        else => return error.InvalidManifest,
    };
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
/// seeds the existing data into the struct before
/// adding the new item
/// it takes an option existing_manifest_data if null it parses the manifest file
/// and gets the data
pub fn appendToManifestFile(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, proj: Project, existing_manifest_data: ?Manifest) !Manifest {
    const existing_data = existing_manifest_data orelse try parseManifestFile(io, allocator, dir);
    // `existing_manifest_data.projects` is a []Project allocated by
    // parseManifestFile. The .dir/.git strings inside are freed by the
    // block below (via the ArrayList copies); this frees the struct array
    // itself to avoid leaking it.
    defer {
        if (existing_data.projects.len > 0) {
            allocator.free(existing_data.projects);
        }
    }
    var projects: std.ArrayList(Project) = .empty;
    defer projects.deinit(allocator);

    // seeding the existing manifest file data
    for (existing_data.projects) |existing| {
        try projects.append(allocator, existing);
    }
    try projects.append(allocator, proj);
    const manifestData: Manifest = .{
        .version = existing_data.version,
        .projects = projects.items,
    };

    try writeManifestFile(io, allocator, dir, manifestData);
    defer {
        for (projects.items) |p| {
            allocator.free(p.dir);
            allocator.free(p.git);
        }
    }

    return manifestData;
}

/// returns true if the project exists in the manifest file
pub fn doesProjectExistInManifestFile(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8) !bool {
    const existing_data = try parseManifestFile(io, allocator, dir);
    // parseManifestFile allocates: the []Project array AND every .dir/.git
    // string inside. Freeing the array alone leaks the strings all three
    // must be freed. Order: strings first (looping the array), then array.
    defer {
        freeManifest(allocator, existing_data);
    }

    for (existing_data.projects) |data| {
        if (std.mem.eql(u8, data.dir, projDir)) {
            return true;
        }
    }
    return false;
}

/// removes a project from the manifest file by dir name.
/// does NOT delete the dir from disk at least for now.
/// Returns `error.ProjectNotFound` if `projDir` isn't in the manifest.
pub fn removeFromManifestFile(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8, existing_manifest_data: ?Manifest) !void {
    const existing_data = existing_manifest_data orelse try parseManifestFile(io, allocator, dir);
    // freeManifest frees every string + the array. The ArrayList below holds
    // shallow copies (same string pointers), but we've already written the
    // file by the time this runs, so the dangling pointers are never read.
    defer freeManifest(allocator, existing_data);

    var projects: std.ArrayList(Project) = .empty;
    defer projects.deinit(allocator);

    // Append every project EXCEPT the one matching projDir.
    for (existing_data.projects) |data| {
        if (std.mem.eql(u8, data.dir, projDir)) continue;
        try projects.append(allocator, data);
    }

    // If nothing was skipped, the project wasn't in the manifest.
    if (projects.items.len == existing_data.projects.len) {
        return error.ProjectNotFound;
    }

    const manifest_data: Manifest = .{
        .version = existing_data.version,
        .projects = projects.items,
    };

    try writeManifestFile(io, allocator, dir, manifest_data);
}

/// looks up a project by dir name. Returns null if not found.
/// The returned Project's .dir/.git are duped into `allocator` so they
/// outlive this function's internal cleanup. Caller must free them.
pub fn getProjectFromManifest(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8, existing_manifest_data: ?Manifest) !?Project {
    const existing_data = existing_manifest_data orelse try parseManifestFile(io, allocator, dir);
    defer freeManifest(allocator, existing_data);

    for (existing_data.projects) |data| {
        if (std.mem.eql(u8, data.dir, projDir)) {
            // Dupe so the returned strings survive freeManifest's defer.
            return .{
                .dir = try allocator.dupe(u8, data.dir),
                .git = try allocator.dupe(u8, data.git),
            };
        }
    }
    return null;
}

/// Serializes `data` and atomically replaces the manifest file.
///
/// The JSON is written to a temporary file which is then renamed over
/// `mf.manifest.json`, so a crash mid-write cannot leave a truncated or
/// corrupt manifest behind.
pub fn writeManifestFile(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, data: Manifest) !void {
    var buf: std.Io.Writer.Allocating = .init(allocator);
    defer buf.deinit();

    try buf.writer.print("{f}", .{std.json.fmt(data, .{ .whitespace = .indent_2 })});

    var atomic = try dir.createFileAtomic(io, FILE_NAME, .{ .replace = true });
    defer atomic.deinit(io);

    try atomic.file.writeStreamingAll(io, buf.written());
    try atomic.file.sync(io);
    try atomic.replace(io);
}

/// Returns where the most recent parse failure occurred, if it can be
/// determined. Used by `main` to turn `error.InvalidManifest` into an
/// actionable message with a line/column.
pub fn manifestErrorLocation(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) ?struct { line: u64, column: u64 } {
    const json_data = dir.readFileAlloc(io, FILE_NAME, allocator, .unlimited) catch return null;
    defer allocator.free(json_data);
    if (json_data.len == 0) return null;

    var scanner = std.json.Scanner.initCompleteInput(allocator, json_data);
    defer scanner.deinit();

    var diagnostics: std.json.Diagnostics = .{};
    scanner.enableDiagnostics(&diagnostics);

    const parsed = std.json.parseFromTokenSource(Manifest, allocator, &scanner, .{
        .ignore_unknown_fields = true,
    }) catch {
        return .{
            .line = diagnostics.getLine(),
            .column = diagnostics.getColumn(),
        };
    };
    parsed.deinit();
    return null;
}

/// Frees everything parseManifestFile allocated: each project's .dir/.git
/// strings, then the []Project array. Safe to call on the empty-manifest
/// case (static &.{} is not freed).
pub fn freeManifest(allocator: std.mem.Allocator, m: Manifest) void {
    for (m.projects) |p| {
        allocator.free(p.dir);
        allocator.free(p.git);
    }
    if (m.projects.len > 0) {
        allocator.free(m.projects);
    }
}
