const global = @import("../global.zig");

/// struct for the manifest json file structure
pub const Manifest = struct {
    version: u32,
    projects: []Project,
};

pub const Project  = struct {
    dir: global.String,
    git: global.String,
};