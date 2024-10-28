const std = @import("std");
const pr = std.io.getStdOut().writer();

const eql = std.mem.eql;
const ip = std.ascii.isPrint;

// var outputType: []const u8 = undefined;
const outputPair = .{ []const u8, []const u8 };

//maybe the flow should be:
// print each 128 bytes in hex and ascii to a buffer (pre-prep the lines)
// print to stdout with a marker in octal
// openFile would then only open the file and place file contents into a container
// could also have it be able to write to a file with a flag or smth
// or a separate function

pub fn openFile(filename: []const u8, allocator: std.mem.Allocator, buffer: *[]const u8) void {
    // Get file handler and defer it closing
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return;
    };
    defer file.close();

    const stat = file.stat() catch |err| {
        std.log.err("Failed to read file metadata: {s}", .{@errorName(err)});
        return;
    };

    buffer.* = file.readToEndAlloc(allocator, stat.size) catch |err| {
        std.log.err("Failed to read file: {s}", .{@errorName(err)});
        return;
    };
}

fn bytesToHex(bytes: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    for (bytes) |byte| {
        try result.writer().print("{x:0>2}", .{byte});
    }

    return result.toOwnedSlice();
}

fn processCommandLineArgs(args: *std.process.ArgIterator, allocator: std.mem.Allocator) !void {
    var inputBuffer: []const u8 = undefined;

    while (args.next()) |arg| {
        if (eql(u8, arg, "--help") or eql(u8, arg, "-h")) {
            try pr.print("Usage: zxd [flags] [data or files]\n", .{});
            try pr.print("\t--help or -h: print this message\n", .{});
            try pr.print("\t--hex: print data in hexadecimal\n", .{});
            try pr.print("\t--file: read file in [datatype] \n", .{});
        } else if (eql(u8, arg, "--hex")) {
            continue;
        } else if (eql(u8, arg, "--file")) {
            openFile(args.next().?, allocator, &inputBuffer);
            const hexString = try bytesToHex(inputBuffer, allocator);
            defer allocator.free(hexString);

            var i: usize = 0;
            while (i < hexString.len) {
                // Figure out how big the current line/chunk is
                const chunk_size = @min(hexString.len - i, 32);
                const chunk = hexString[i..(i + chunk_size)];

                // Translate the hex position to ascii position
                const asciiStart: usize = i / 2;
                const asciiEnd: usize = asciiStart + (chunk_size / 2);

                // Print positions in octal
                try pr.print("{o:0>8}: ", .{i / 16});
                // Pring the converted hex
                var j: usize = 0;
                while (j < chunk_size) : (j += 4) {
                    try pr.print("{s} ", .{if (j + 4 <= chunk_size) chunk[j..(j + 4)] else chunk[j..]});
                }

                // Print the associated ascii
                try pr.print(" ", .{});
                for (inputBuffer[asciiStart..asciiEnd]) |char| {
                    if (ip(char)) {
                        try pr.print("{c}", .{char});
                    } else {
                        try pr.print("", .{});
                    }
                }
                try pr.print("\n", .{});
                // Update the position
                i += chunk_size;
            }
        }
    }
}

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

test "bytesToHex" {
    const allocator = std.testing.allocator;
    const input = "Hello World";
    const expected = "48656c6c6f20576f726c64";

    const result = try bytesToHex(input, allocator);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}
