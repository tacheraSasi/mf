const std = @import("std");

const stdio = @import("stdio");

/// clones/replicates the entire dir cloning each repo/project as per manifest file
pub fn Clone(console: *stdio.Console) !void {
    try console.printLine("cloning the entire project dir, each repo one by one", .{});
}
