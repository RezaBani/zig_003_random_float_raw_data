const std = @import("std");

pub const ArgsError = error{
    TooManyArgs,
};

pub const ArgumentsOrder = enum(usize) {
    // ExecutableName = 0,
    Count = 1,
};

pub const DEFAULT_COUNT: usize = 10000;
pub const MAX_ARGS_COUNT: usize = 2;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try readArgs(allocator);
    const count = try parseArgs(args);
    try createFile("zig-out/bin/raw.data", count);
}

fn readArgs(allocator: std.mem.Allocator) ![][]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    var argsArray = std.ArrayList([]u8).init(allocator);
    while (args.next()) |arg| {
        const buf = try allocator.alloc(u8, arg.len);
        @memcpy(buf, arg);
        try argsArray.append(buf);
    }
    return argsArray.toOwnedSlice();
}

pub fn parseArgs(args: [][]const u8) !usize {
    if (args.len > MAX_ARGS_COUNT) {
        std.debug.print("This executable accepts only 1 arguments but more than 1 argument is provided!\nIf you see this in test suit, it's fine\n", .{});
        return ArgsError.TooManyArgs;
    }
    const count: usize = if (args.len > 1)
        try std.fmt.parseUnsigned(usize, args[@intFromEnum(ArgumentsOrder.Count)], 10)
    else
        DEFAULT_COUNT;
    return count;
}

pub fn createFile(relative_path: []const u8, count: usize) !void {
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
