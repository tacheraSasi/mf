const std = @import("std");

pub const Subcommand = enum { none, scan, clone, status, rm, add };

pub const CliFlags = struct {
    subcommand: Subcommand = .none,
    verbose: bool = false,
};

pub const ArgsParser = struct {
    cli_flags: CliFlags,

    /// positional args after the subcommand
    positional_args: []const []const u8, 

    const Self = @This();

    pub fn parse(args: []const [:0]const u8) !Self {
        var flags: CliFlags = .{};
        var positional: []const []const u8 = &.{};

        // Just the program name, nothing to parse here haha.
        if (args.len <= 1) return .{ .cli_flags = flags, .positional_args = positional };

        var i: usize = 1;

        // --- Subcommand detection ---
        // First non-flag arg is the subcommand. `stringToEnum` does the
        // string -> enum lookup at runtime; returns null on no match.
        if (args[i].len > 0 and args[i][0] != '-') {
            flags.subcommand = std.meta.stringToEnum(Subcommand, args[i])
                orelse return error.UnknownSubcommand;
            i += 1;
        }

        // --- Flag detection via comptime reflection ---
        // Walk remaining args. Anything starting with "--" is a flag;
        // the first non-flag arg ends parsing (rest are positionals).
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (arg.len < 2 or !std.mem.startsWith(u8, arg, "--")) {
                positional = args[i..];
                break;
            }

            const flag_name = arg[2..]; // stripping "--"

            // `inline for` unrolls at comptime. Each iteration becomes a
            // separate `if` block in the generated code. Required because
            // `@field` needs a comptime-known field name.
            var found = false;
            inline for (@typeInfo(CliFlags).@"struct".fields) |field| {
                // I only match bool fields `subcommand` is an enum, i skip it.
                if (field.type != bool) continue;

                if (std.mem.eql(u8, field.name, flag_name)) {
                    @field(flags, field.name) = true; // settin by comptime name
                    found = true;
                }
            }

            if (!found) return error.UnknownFlag;
        }

        return .{ .cli_flags = flags, .args = positional };
    }

    pub fn Test(self: *const Self) void {
        std.debug.print("subcommand: {s}\n", .{@tagName(self.cli_flags.subcommand)});
        std.debug.print("verbose: {}\n", .{self.cli_flags.verbose});
        std.debug.print("positionals: {s}\n", .{self.args});
    }
};
