const std = @import("std");

pub const ArgsParser = struct {
    args: []const []const u8,

    const Self = @This();
    pub fn parse(args: []const [:0]const u8) !Self{
        return Self{
            .args = args[1..]
        };
    }

    pub fn Test(self: *const Self)void{
        for (self.args) |arg| {
            std.debug.print("{s}\n",.{arg});
        }
    }
};

/// CliFlags
pub const CliFlags = struct {
    
};