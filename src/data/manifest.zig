const global = @import("../global.zig");
pub const Manifest = struct {
    version: u32,
    projects: []Project,
};

pub const Project  = struct {
    dir: global.String,
    git: global.String,
};