const std = @import("std");
const pr = std.io.getStdOut().writer();

const eql = std.mem.eql;

var outputType: []const u8 = undefined;

//maybe the flow should be:
// print each 128 bytes in hex and ascii to a buffer (pre-prep the lines)
// print to stdout with a marker in octal
// openFile would then only open the file and place file contents into a container
// could also have it be able to write to a file with a flag or smth
// or a separate function

pub fn openFile(filename: []const u8, allocator: std.mem.Allocator, outputContainer: anytype) void {
    // Get file handler and defer it closing
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        std.log.err("Failed to open file {s}", .{@errorName(err)});
        return;
    };
    defer file.close();

    // Read from file stream until we hit the delimiter or EOF
    // Log errors if unable to open the file
    var i: usize = 0;
    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        return;
    }) |line| {
        defer allocator.free(line);

        // Change procedure based on if we have a buffer passed in, mostly for tests
        //   - null             --> print to stdOut
        //   - std.ArrayList    --> print to arraylist buffer (maybe useful in the future? idk)
        switch (@TypeOf(outputContainer)) {
            @TypeOf(null) => {
                pr.print("{o}: {} {s}\n", .{ i, std.fmt.fmtSliceHexLower(line), line }) catch |err| {
                    std.log.err("Failed to print line {d}: {s}", .{ i, @errorName(err) });
                    continue;
                };
            },
            @TypeOf(std.ArrayList([]const u8)) => {
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
            openFile(args.next().?, allocator, null);
        }
    }
}

// fn bytesToHex(inputBytes: []const u8, outputContainer: anytype) []const u8 {
//     _ = outputContainer;
//     return std.fmt.fmtSliceHexLower(inputBytes);
// }

pub fn main() !void {
    // Init allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    // Handle CLI args
    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    _ = args.skip();

    try processCommandLineArgs(&args, gpa.allocator());
}
