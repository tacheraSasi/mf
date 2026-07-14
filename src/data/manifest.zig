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

/// parses an existing manifest file and returns the `Manifest` struct
pub fn parseManifestFile(io:std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !Manifest {
    const json_data = try dir.readFileAlloc(io, FILE_NAME, allocator, .unlimited);
}