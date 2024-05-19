const std = @import("std");
const allocator = std.debug.global_allocator;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    const stderr_file = std.io.getStdErr().writer();
    var sw = std.io.bufferedWriter(stdout_file);
    var ew = std.io.bufferedWriter(stderr_file);
    const stderr = ew.writer();
    const stdout = sw.writer();
    defer ew.flush() catch unreachable;
    defer sw.flush() catch unreachable;

    //    var args = std.process.args();
    const args = std.os.argv;
    if (args.len <= 1) {
        // тут брать cwd
        return;
    }
    var dir = std.fs.openDirAbsoluteZ(args[1], .{ .iterate = true }) catch |err| {
        switch (err) {
            error.NoSpaceLeft => {
                try stderr.print("fi: no space left for '{s}'\n", .{args[1]});
            },
            error.FileNotFound => {
                try stderr.print("fi: path not found for '{s}'\n", .{args[1]});
            },
            error.FileTooBig => {
                try stderr.print("fi: file too big for '{s}'\n", .{args[1]});
            },
            error.AccessDenied => {
                try stderr.print("fi: access denied for '{s}'\n", .{args[1]});
            },
            error.DeviceBusy => {
                try stderr.print("fi: device busy for '{s}'\n", .{args[1]});
            },
            error.NameTooLong => {
                try stderr.print("fi: name too long for '{s}'\n", .{args[1]});
            },
            // too lazy
            else => {
                try stderr.print("fi: can't open '{s}'\n", .{args[1]});
            },
        }
        return;
    };
    var iterator = dir.iterate();
    while (try iterator.next()) |it| {
        try stdout.print("{s}\n", .{it.name});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
