const std = @import("std");

const stdio = @import("stdio");

const args_parser = @import("args.zig").ArgsParser;
const cmd = @import("cmd.zig");
const core = @import("core/core.zig");
const help = @import("help.zig");
const manifest = @import("manifest.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var console_write_buf: [4096]u8 = undefined;
    var console_read_buf: [4096]u8 = undefined;

    var console: stdio.Console = undefined;
    console.init(io, &console_write_buf, &console_read_buf);

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    const parser = args_parser.parse(allocator, args) catch |err| switch (err) {
        error.UnknownSubcommand, error.UnknownFlag => {
            try console.printLine("Invalid usage: \n{s}", .{
                help.HelpText(),
            });
            return;
        },
        else => {
            try console.printLine("Something went wrong Failed to Parse Args \n{s}",.{
                help.HelpText(),
            });
        }
    };

    // TODO: i will an optional flags to set the path
    // For now operate on the current working directory. The opened `dir` handle IS
    // the process cwd, so all relative paths (manifest file, repo subdirs)
    // resolve correctly without any hardcoded base path.
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, ".", .{ .iterate = true });
    defer dir.close(io);

    const cliFlags = parser.cli_flags;
    const positional_args = parser.positional_args;
    defer allocator.free(positional_args);

    switch (cliFlags.subcommand) {
        .scan => try core.Scan(io, allocator, dir, &console),
        .add => {
            if (positional_args.len == 0) {
                try console.printLine("Invalid usage: missing git url \n{s}", .{
                    help.HelpText(),
                });
                return;
            }
            try core.Add(io, allocator, dir, positional_args[0], &console);
        },
        .status => try core.Status(io, allocator, dir, &console),
        .rm => {
            if (positional_args.len == 0) {
                try console.printLine("Invalid usage: missing project dir name \n{s}", .{
                    help.HelpText(),
                });
                return;
            }
            try core.Rm(io, allocator, dir, positional_args[0], cliFlags.purge, &console);
        },
        .init => {
            try core.Init(io, dir, manifest.FILE_NAME, &console);
        },
        .nuke => {
            try console.printLine("not implemented", .{});
        },
        .none => try console.printLine(help.HelpText(), .{}),
    }
}
