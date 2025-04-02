const std = @import("std");

pub fn main() !void {
    try createFile("zig-out/bin/raw.data", 10000);
}

fn createFile(relative_path: []const u8, count: usize) !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile(relative_path, .{});
    defer file.close();
    const time = std.time.timestamp();
    var seed = std.Random.DefaultPrng.init(@intCast(time));
    const random = std.Random.DefaultPrng.random(&seed);
    var buffer: [8]u8 = undefined;
    @memset(&buffer, 0);
    for (0..count) |_| {
        const number = random.float(f64);
        const bytes = try std.fmt.bufPrint(&buffer, "{d:7.6}", .{number});
        _ = try file.write(bytes);
    }
}

test "simple test" {
    const cwd = std.fs.cwd();
    const path = "zig-out/bin/test.data";
    {
        const count = 16000;
        try createFile(path, count);
        const file = try cwd.openFile(path, .{});
        defer file.close();
        const allocator = std.testing.allocator;
        const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        defer allocator.free(content);
        try std.testing.expectEqual(content.len, count * 8);
    }
    try cwd.deleteFile(path);
    try std.testing.expectError(std.fs.File.OpenError.FileNotFound, cwd.openFile(path, .{}));
}
