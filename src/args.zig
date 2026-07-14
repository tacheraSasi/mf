const std = @import("std");

pub const ArgsParser = struct {
    pub fn parse(args: []const [:0]const u8) !void{
        for (args) |arg| {
            std.debug.print("{s}\n", .{arg});
        }
    }
};