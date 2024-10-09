const std = @import("std");
const pr = std.io.getStdOut().writer();

const eql = std.mem.eql;

var outputType: []const u8 = undefined;

// try pr.print("", .{});

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
            else => @compileError("Unsupported buffer type"),
        }

        i += 1;
    }
}

fn processCommandLineArgs(args: *std.process.ArgIterator, allocator: std.mem.Allocator) !void {
    while (args.next()) |arg| {
        if (eql(u8, arg, "--help") or eql(u8, arg, "-h")) {
            try pr.print("Usage: zxd [flags] [data or files]\n", .{});
            try pr.print("\t--help or -h: print this message\n", .{});
            try pr.print("\t--hex: print data in hexadecimal\n", .{});
            try pr.print("\t--file: read file in [datatype] \n", .{});
        } else if (eql(u8, arg, "--hex")) {
            outputType = "{X}";
        } else if (eql(u8, arg, "--file")) {
            openFile(args.next().?, allocator, undefined);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    // openFile("zxd.zig", gpa.allocator(), undefined);

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    _ = args.skip();

    try processCommandLineArgs(&args, gpa.allocator());
}
