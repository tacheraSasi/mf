const std = @import("std");
const stdio = @import("stdio");
const manifest = @import("../manifest.zig");


pub fn Rm(io: std.Io, allocator: std.mem.Allocator, dir: std.Io.Dir, projDir: []const u8, console: *stdio.Console) !void{
    const exists = try manifest.doesProjectExistInManifestFile(io, allocator, dir, projDir);
    if (!exists){
        try console.printLine("The project {s} does not exist in the manifest file run mf scan to include it",.{projDir});
        return;
    }

    const proj = try manifest.getProjectFromManifest(io, allocator, dir, projDir);

    try manifest.removeFromManifestFile(io, allocator, dir, proj);
}