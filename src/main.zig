const std = @import("std");
const cmd = @import("cmd.zig");
const manifest = @import("manifest.zig");
const help = @import("help.zig");
const add = @import("core/add.zig");
const scan = @import("core/scan.zig");
const constants = @import("constants.zig");

const args_parser = @import("args.zig").ArgsParser;
const VERSION = 1;

const Io = std.Io;


pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    // const parser = args_parser.parse(args) catch {
    //     std.debug.print("{s}",help.HelpText()); // for now i assume any error will only be invalid flag or subcommand
    // };
    const parser = try args_parser.parse(args);

    const base = constants.BASE;
    const cwd = std.Io.Dir.cwd();
    const dir = try cwd.openDir(io, base, .{ .iterate = true });
    defer dir.close(io);

    const cliFlags = parser.cli_flags;
    const positional_args = parser.positional_args;
    
    switch (cliFlags.subcommand) {
        .scan => try scan.Scan(io, allocator, dir),
        .add => try add.Add(io, allocator, dir,positional_args[0]),
        .none => std.debug.print("usage: mf <scan|clone|status|rm|add> [options]\n", .{}),
        else => std.debug.print("not implemented yet\n", .{}),
    }
}

