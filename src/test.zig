const std = @import("std");

const exe = @import("zig_003_random_float_raw_data_exe");

test "simple test" {
    const cwd = std.fs.cwd();
    const path = "zig-out/bin/test.data";
    const allocator = std.testing.allocator;

    const argumentSetOkEmpty: [][]const u8 = @constCast(&[_][]const u8{"executableName"});
    const argumentSetOkOne: [][]const u8 = @constCast(&[_][]const u8{ "executableName", "20" });
    const argumentSetBad: [][]const u8 = @constCast(&[_][]const u8{ "executableName", "garbage" });
    const argumentSetBadExtra: [][]const u8 = @constCast(&[_][]const u8{ "executableName", "20", "extra" });

    try std.testing.expectEqual(exe.DEFAULT_COUNT, (try exe.parseArgs(argumentSetOkEmpty)).count);
    try std.testing.expectEqual(try std.fmt.parseUnsigned(usize, argumentSetOkOne[@intFromEnum(exe.ArgumentsOrder.Count)], 10), (try exe.parseArgs(argumentSetOkOne)).count);
    try std.testing.expectError(std.fmt.ParseIntError.InvalidCharacter, exe.parseArgs(argumentSetBad));
    try std.testing.expectError(exe.ArgsError.TooManyArgs, exe.parseArgs(argumentSetBadExtra));
    {
        var okArgs = std.ArrayList([][]const u8).init(allocator);
        defer okArgs.deinit();
        try okArgs.append(argumentSetOkOne);
        try okArgs.append(argumentSetOkEmpty);
        for (okArgs.items) |rawArgs| {
            const args = try exe.parseArgs(rawArgs);
            try exe.createFile(path, args);
            const file = try cwd.openFile(path, .{});
            defer file.close();
            const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
            defer allocator.free(content);
            try std.testing.expectEqual(content.len, args.count * 8);
        }
    }
    try cwd.deleteFile(path);
    try std.testing.expectError(std.fs.File.OpenError.FileNotFound, cwd.openFile(path, .{}));
}
