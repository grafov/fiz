const std = @import("std");

const str = []const u8;
const defaultIcon: str = " ";
const fileIcon: str = " ";
const folderIcon: str = "🗀";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout_file = std.io.getStdOut().writer();
    const stderr_file = std.io.getStdErr().writer();
    var sw = std.io.bufferedWriter(stdout_file);
    var ew = std.io.bufferedWriter(stderr_file);
    const stderr = ew.writer();
    const stdout = sw.writer();
    defer ew.flush() catch unreachable;
    defer sw.flush() catch unreachable;

    var fpath: [*:0]u8 = undefined;
    if (std.os.argv.len > 1) {
        fpath = std.os.argv[1];
    } else {
        const cwd = try std.process.getEnvVarOwned(allocator, "PWD");
        defer allocator.free(cwd);
        fpath = try allocator.dupeZ(u8, cwd);
    }
    if (!std.fs.path.isAbsoluteZ(fpath)) {
        const cwd = try std.process.getEnvVarOwned(allocator, "PWD");
        defer allocator.free(cwd);
        const paths = [_][]u8{ cwd, std.mem.span(fpath) };
        fpath = try std.fs.path.joinZ(allocator, &paths);
    }
    var dir = std.fs.openDirAbsoluteZ(fpath, .{ .iterate = true }) catch |err| {
        switch (err) {
            error.NoSpaceLeft => {
                try stderr.print("fi: no space left for '{s}'\n", .{fpath});
            },
            error.FileNotFound => {
                try stderr.print("fi: path not found for '{s}'\n", .{fpath});
            },
            error.FileTooBig => {
                try stderr.print("fi: file too big for '{s}'\n", .{fpath});
            },
            error.AccessDenied => {
                try stderr.print("fi: access denied for '{s}'\n", .{fpath});
            },
            error.DeviceBusy => {
                try stderr.print("fi: device busy for '{s}'\n", .{fpath});
            },
            error.NameTooLong => {
                try stderr.print("fi: name too long for '{s}'\n", .{fpath});
            },
            // too lazy
            else => {
                try stderr.print("fi: can't open '{s}'\n", .{fpath});
            },
        }
        return;
    };
    var iterator = dir.iterate();
    var buf: [1024]u8 = undefined;
    var size: str = "";
    var mask: str = "";
    var icon: str = "";
    while (try iterator.next()) |it| {
        switch (it.kind) {
            std.fs.File.Kind.file => {
                const stat = std.fs.Dir.statFile(dir, it.name) catch |err| {
                    try stderr.print("fi: can't stat file '{s}: {}'\n", .{ it.name, err });
                    continue;
                };
                size = std.fmt.bufPrint(&buf, "{s:.2}", .{std.fmt.fmtIntSizeBin(stat.size)}) catch |err| {
                    try stderr.print("fi: not enough memory for string conversion: {}\n", .{err});
                    continue;
                };
                mask = displayMask(stat.mode);
                icon = fileIcon;
            },
            std.fs.File.Kind.directory => {
                const stat = std.fs.Dir.statFile(dir, it.name) catch |err| {
                    try stderr.print("fi: can't stat file '{s}: {}'\n", .{ it.name, err });
                    continue;
                };
                size = std.fmt.bufPrint(&buf, "{s:.2}", .{std.fmt.fmtIntSizeBin(stat.size)}) catch |err| {
                    try stderr.print("fi: not enough memory for string conversion: {}\n", .{err});
                    continue;
                };
                mask = displayMask(stat.mode);
                icon = folderIcon;
            },
            else => {
                size = "";
                mask = "";
                icon = defaultIcon;
            },
        }
        try stdout.print("{s:<1}{s:15} {s}\n", .{ icon, size, it.name });
    }
}

fn displayMask(m: std.fs.File.Mode) str {
    if (m == 0) {
        return ""; // amask.get(0);
    }
    return "";
}

var amask = std.AutoArrayHashMapUnmanaged(u8, []const u8){
    .{ 0b000, "☰" }, // ---
    .{ 0b001, "☴" }, // --x
    .{ 0b010, "☲" }, // -w-
    .{ 0b011, "☶" }, // -wx
    .{ 0b100, "☱" }, // r--
    .{ 0b101, "☵" }, // r-x
    .{ 0b110, "☳" }, // rw-
    .{ 0b111, "☷" }, // rwx
};

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
