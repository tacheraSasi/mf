const std = @import("std");
const cmd = @import("../cmd.zig");

/// add a new project
/// clones the repo then adds the dir and git url to the manifest
/// mf add https://github/.....
pub fn Add(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, git_url: []const u8) !void{
    
    
}