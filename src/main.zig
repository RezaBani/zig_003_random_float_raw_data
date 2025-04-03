const std = @import("std");

pub const ArgsError = error{
    TooManyArgs,
};

pub const ArgumentsOrder = enum(usize) {
    // ExecutableName = 0,
    Count = 1,
};

pub const CommandLineArguments = struct {
    count: usize,
};

pub const DEFAULT_COUNT: usize = 10000;
pub const MAX_ARGS_COUNT: usize = 2;

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const rawArgs = readArgs(allocator) catch |err| switch (err) {
        std.mem.Allocator.Error.OutOfMemory => {
            std.debug.print("{}\n", .{err});
            std.debug.print("Not enough emory to store args", .{});
            std.process.exit(1);
        },
    };
    const args = parseArgs(rawArgs) catch |err| switch (err) {
        ArgsError.TooManyArgs => {
            std.debug.print("{}\n", .{err});
            std.debug.print("This executable accepts only {d} arguments but more than {} argument is provided!\n", .{ MAX_ARGS_COUNT - 1, MAX_ARGS_COUNT - 1 });
            std.process.exit(1);
        },
        std.fmt.ParseIntError.InvalidCharacter => {
            std.debug.print("{}\n", .{err});
            std.debug.print("argument {s} can't be converted to unsigned interger\n", .{rawArgs[@intFromEnum(ArgumentsOrder.Count)]});
            std.process.exit(1);
        },
        std.fmt.ParseIntError.Overflow => {
            std.debug.print("{}\n", .{err});
            std.debug.print("argument {s} too big when converted to unsigned interger\n", .{rawArgs[@intFromEnum(ArgumentsOrder.Count)]});
            std.process.exit(1);
        },
    };
    createFile("zig-out/bin/raw.data", args) catch |err| switch (err) {
        std.fmt.BufPrintError.NoSpaceLeft => {
            std.debug.print("{}\n", .{err});
            std.debug.print("Buffer too small for number to fit in\n", .{});
            std.process.exit(1);
        },
        else => {
            std.debug.print("{}\n", .{err});
            std.debug.print("error related to file operation happened", .{});
            std.process.exit(1);
        },
    };
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
    const slice = try argsArray.toOwnedSlice();
    return slice;
}

pub fn parseArgs(args: [][]const u8) !CommandLineArguments {
    if (args.len > MAX_ARGS_COUNT) {
        return ArgsError.TooManyArgs;
    }
    const count: usize = if (args.len > 1)
        try std.fmt.parseUnsigned(usize, args[@intFromEnum(ArgumentsOrder.Count)], 10)
    else
        DEFAULT_COUNT;
    return CommandLineArguments{
        .count = count,
    };
}

pub fn createFile(relative_path: []const u8, args: CommandLineArguments) !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile(relative_path, .{});
    defer file.close();
    const time = std.time.timestamp();
    var seed = std.Random.DefaultPrng.init(@intCast(time));
    const random = std.Random.DefaultPrng.random(&seed);
    var buffer: [8]u8 = undefined;
    @memset(&buffer, 0);
    for (0..args.count) |_| {
        const number = random.float(f64);
        const bytes = try std.fmt.bufPrint(&buffer, "{d:7.6}", .{number});
        _ = try file.write(bytes);
    }
}
