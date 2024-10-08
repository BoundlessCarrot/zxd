const std = @import("std");
const pr = std.io.getStdOut().writer();

pub fn openFile(filename: []const u8, allocator: std.mem.Allocator) void {
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        std.log.err("Failed to open file {s}", .{@errorName(err)});
        return;
    };

    defer file.close();

    var i: usize = 0;

    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        return;
    }) |line| {
        defer allocator.free(line);
        pr.print("line {d}: {s}\n", .{ i, line });
        i += 1;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    openFile("xxd.zig", gpa.allocator());
}
