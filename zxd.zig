const std = @import("std");
const pr = std.io.getStdOut().writer();

const eql = std.mem.eql;

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

fn bytesToHex(bytes: []const u8, buffer: *std.ArrayList([]const u8)) !void {
    for (0..bytes.len) |byte_idx| {
        switch (byte_idx % 2 == 0) {
            true => {
                var hex_buf: [16]u8 = undefined;
                const converted = try std.fmt.bufPrint(&hex_buf, "{x}", .{bytes[byte_idx]});
                try buffer.append(converted);
            },
            false => continue,
        }
    }
}

fn processCommandLineArgs(args: *std.process.ArgIterator, allocator: std.mem.Allocator) !void {
    var inputBuffer: []const u8 = undefined;
    var hexBuffer = std.ArrayList([]const u8).init(allocator);

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
            try bytesToHex(inputBuffer, &hexBuffer);

            var i: usize = 0;
            while (i < hexBuffer.items.len) {
                const chunk_size = @min(hexBuffer.items.len - i, 8);
                const chunk = hexBuffer.items[i..(i + chunk_size)];

                try pr.print("Chunk {d}: ", .{i / 8 + 1});
                for (chunk) |item| {
                    try pr.print("{x} ", .{item});
                }
                try pr.print("{s}", .{inputBuffer[i..(i + (chunk_size * 2))]});
                try pr.print("\n", .{});

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
