const std = @import("std");
const pr = std.io.getStdOut().writer();

pub fn openFile(filename: []const u8, allocator: std.mem.Allocator, outputContainer: anytype) void {
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
        switch (@TypeOf(outputContainer)) {
            @TypeOf(undefined) => {
                pr.print("line {d}: {s}\n", .{ i, line }) catch |err| {
                    std.log.err("Failed to print line {d}: {s}", .{ i, @errorName(err) });
                    continue;
                };
            },
            std.ArrayList([]const u8) => {
                outputContainer.append(line) catch |err| {
                    std.log.err("Buffer could not be added to, stopped at line {d}: {s}", .{ i, @errorName(err) });
                    return;
                };
            },
            else => @compileError("Unsupported buffer type, come and add it yourself if you really want to"),
        }

        i += 1;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    openFile("xxd.zig", gpa.allocator(), undefined);
}
