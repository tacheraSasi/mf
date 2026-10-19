const std = @import("std");

const stdio = @import("stdio");

const args_parser = @import("args.zig").ArgsParser;
const cmd = @import("cmd.zig");
const core = @import("core/core.zig");
const help = @import("help.zig");
const manifest = @import("manifest.zig");
const SUBCOMMAND = @import("args.zig").Subcommand;

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
            try console.printLine("Invalid usage: {s} \n{s}", .{
                @errorName(err),
                help.HelpText(),
            });
            std.process.exit(2);
        },
        error.OutOfMemory => {
            try console.printLine("Out of memory", .{});
            std.process.exit(1);
        },
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

    const parsed_subcommands: SUBCOMMAND = if (cliFlags.help) .none else cliFlags.subcommand;

    const command_result: anyerror!void = switch (parsed_subcommands) {
        .scan => core.Scan(io, allocator, dir, &console),
        .add => add: {
            if (positional_args.len == 0) {
                try console.printLine("Invalid usage: missing git url \n{s}", .{
                    help.HelpText(),
                });
                std.process.exit(2);
            }
            break :add core.Add(io, allocator, dir, positional_args[0], &console);
        },
        .clone => core.Clone(io, allocator, dir, &console),
        .status => core.Status(io, allocator, dir, &console),
        .rm => rm: {
            if (positional_args.len == 0) {
                try console.printLine("Invalid usage: missing project dir name \n{s}", .{
                    help.HelpText(),
                });
                std.process.exit(2);
            }
            // Error boundary (#38): Rm reports failures as errors, main maps
            // them to a message + exit code. Anything unexpected propagates.
            break :rm core.Rm(io, allocator, dir, positional_args[0], cliFlags.purge, &console) catch |err| switch (err) {
                error.ProjectNotFound => {
                    try console.printLine("The project {s} does not exist in the manifest file. Run mf scan to include it.", .{positional_args[0]});
                    std.process.exit(1);
                },
                error.PurgeRefused => {
                    try console.printLine("refusing to purge: {s} has uncommitted changes", .{positional_args[0]});
                    std.process.exit(1);
                },
                else => return err,
            };
        },
        .init => core.Init(io, dir, manifest.FILE_NAME, &console),
        .nuke => {
            try console.printLine("not implemented", .{});
            std.process.exit(1);
        },
        .none => console.printLine(help.HelpText(), .{}),
    };

    // Manifest error boundary (#39): turn missing/corrupt manifests into
    // actionable messages instead of a raw stdlib stack trace.
    command_result catch |err| switch (err) {
        error.ManifestNotFound => {
            try console.printLine("{s} not found here; run mf init to create a workspace.", .{manifest.FILE_NAME});
            std.process.exit(1);
        },
        error.InvalidManifestSyntax => {
            if (manifest.manifestErrorLocation(io, allocator, dir)) |loc| {
                try console.printLine("{s} is not valid JSON at line {d}, column {d}; fix it or delete it and run mf init.", .{
                    manifest.FILE_NAME, loc.line, loc.column,
                });
            } else {
                try console.printLine("{s} is not valid JSON; fix it or delete it and run mf init.", .{manifest.FILE_NAME});
            }
            std.process.exit(1);
        },
        error.InvalidManifest => {
            if (manifest.manifestErrorLocation(io, allocator, dir)) |loc| {
                try console.printLine("{s} is not a valid manifest (line {d}, column {d}); fix it or delete it and run mf init.", .{
                    manifest.FILE_NAME, loc.line, loc.column,
                });
            } else {
                try console.printLine("{s} is not a valid manifest; fix it or delete it and run mf init.", .{manifest.FILE_NAME});
            }
            std.process.exit(1);
        },
        else => return err,
    };
}
