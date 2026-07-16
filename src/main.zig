const std = @import("std");
const stdio = @import("stdio");
const cmd = @import("cmd.zig");
const manifest = @import("manifest.zig");
const help = @import("help.zig");
const constants = @import("constants.zig");
const core = @import("core/core.zig");

const args_parser = @import("args.zig").ArgsParser;
const VERSION = 1;


pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var write_buf: [4096]u8 = undefined;
    var read_buf: [4096]u8 = undefined;

    var console: stdio.Console = undefined;
    console.init(io, &write_buf, &read_buf);

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    const parser = try args_parser.parse(args);

    const base = constants.BASE;
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, base, .{ .iterate = true });
    defer dir.close(io);

    const cliFlags = parser.cli_flags;
    const positional_args = parser.positional_args;

    switch (cliFlags.subcommand) {
        .scan => try core.Scan(io, allocator, dir,&console),
        .add => try core.Add(io, allocator, dir, positional_args[0],&console),
        .status => try core.Status(io, allocator, dir,&console),
        .rm => try core.Rm(io, allocator, dir,positional_args[0],&console),
        .nuke => {
            try console.printLine("not implemented yet: rm {s}", .{positional_args[0]});
        },
        .none => try console.printLine(help.HelpText(), .{}),
    }
}
