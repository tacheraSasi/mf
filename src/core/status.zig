const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");
const cmd = @import("../cmd.zig");
const constants = @import("../constants.zig");
const utils = @import("../utils.zig");

pub fn status(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir) !void {
    var write_buf: [4096]u8 = undefined;
    var read_buf: [4096]u8 = undefined;

    var console: stdio.Console = undefined;
    console.init(io, &write_buf, &read_buf);
    const existing_manifest_data = try manifest.parseManifestFile(io, allocator, dir);
    
}

fn statusString(projects: []manifest.Project) !void {
    return 
    \\
    \\
    ;
}