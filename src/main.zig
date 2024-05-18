const std = @import("std");
const allocator = std.debug.global_allocator;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    //    var args = std.process.args();
    const args = std.os.argv;
    if (args.len <= 1) {
        return;
    }
    var dir = std.fs.openDirAbsoluteZ(args[1], .{ .iterate = true }) catch unreachable;
    var iterator = dir.iterate();
    while (try iterator.next()) |it| {
        try stdout.print("{s}\n", .{it.name});
    }
    try bw.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
