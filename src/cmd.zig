const std = @import("std");

pub const Error = error{ ExitCodeFailure, OutOfMemory };

/// runs a shell command i ignore the errors for now
pub fn run(io: std.Io, allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
    });
    defer allocator.free(result.stderr);
    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };

    if (!ok) {
        //TODO: i will figure out a btter way to handle error here later
        allocator.free(result.stdout);
        return error.ExitCodeFailure;
    }

    // Trim trailing whitespace (commands typically emit a trailing newline).
    // trimRight returns a subslice, so we dupe to give the caller a
    // standalone allocation it can free.
    var end = result.stdout.len;
    while (end > 0) : (end -= 1) {
        const c = result.stdout[end - 1];
        if (c != '\n' and c != '\r' and c != ' ' and c != '\t') break;
    }
    if (end == result.stdout.len) return result.stdout; // nothing to trim here

    const trimmed = try allocator.dupe(u8, result.stdout[0..end]);
    allocator.free(result.stdout);
    return trimmed;
}

/// Streams the child's stdout and stderr live to `writer`.
/// Returns the exit status; does not capture the output.
pub fn runStream(
    io: std.Io,
    allocator: std.mem.Allocator,
    argv: []const []const u8,
    writer: *std.Io.Writer,
) !void {
    _ = allocator;
    var child = try std.process.spawn(io, .{ .argv = argv, .stdin = .ignore, .stdout = .pipe, .stderr = .pipe });

    defer child.kill(io);

    // git writes its progress to stderr, so stream that live.
    // stdout we drain into a throwaway discarding writer (or i also stream it mmh).
    var out_buf: [4096]u8 = undefined;
    var err_buf: [4096]u8 = undefined;
    var out_fr = child.stdout.?.reader(io, &out_buf);
    var err_fr = child.stderr.?.reader(io, &err_buf);
    const out_r = &out_fr.interface;
    const err_r = &err_fr.interface;

    _ = err_r.streamRemaining(writer) catch |err| {
        return err;
    };

    //Draining stdout so the pipe does not fill and deadlock the child
    _ = out_r.discardRemaining() catch {};

    const term = try child.wait(io);
    switch (term) {
        .exited => |code| if (code != 0) return error.ExitCodeFailure,
        else => return error.ExitCodeFailure,
    }
}
