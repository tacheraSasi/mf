pub const FILE_NAME = "mf.manifest.json";

/// struct for the manifest json file structure
pub const Manifest = struct {
    version: u32,
    projects: []Project,
};

pub const Project = struct {
    dir: []const u8,
    git: []const u8,
};