const std = @import("std");
const pr = std.io.getStdOut().writer();

const eql = std.mem.eql;
const ip = std.ascii.isPrint;

const OutputType = enum {
    hex,
    binary,
};

const DataContainer = struct {
    allocator: std.mem.Allocator,
    inputBuffer: []const u8 = undefined,
    outputBuffer: []const u8 = undefined,
    outputType: OutputType = OutputType.hex,
    startOffset: usize = 0,
    endOffset: ?usize = null,
    bytesPerLine: usize = 32, // calculated by taking the number of bits and multiplying by 6, need to make that make more sense at some point
    wordSize: usize = 4, //number of characters per item (in a column)

    const Self = @This();

    fn deinit(self: Self) void {
        self.allocator.free(self.inputBuffer);
        self.allocator.free(self.outputBuffer);
    }
};

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

fn bytesToBinary(bytes: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    for (bytes) |byte| {
        try result.writer().print("{b:0>8}", .{byte});
    }

    return result.toOwnedSlice();
}

fn printOutputBuffer(container: DataContainer) !void {
    var startOffset = container.startOffset;
    const endOffset = if (container.endOffset != null) (startOffset + container.endOffset.?) else container.outputBuffer.len;

    var asciiStart: usize = undefined;
    var asciiEnd: usize = undefined;

    while (startOffset < endOffset) {
        // Figure out how big the current line/chunk is
        const chunk_size = @min(endOffset - startOffset, container.bytesPerLine);
        const chunk = container.outputBuffer[startOffset..(startOffset + chunk_size)];

        // Translate the translated position to ascii position
        switch (container.outputType) {
            OutputType.hex => {
                asciiStart = startOffset / 2;
                asciiEnd = asciiStart + (chunk_size / 2);
            },
            OutputType.binary => {
                asciiStart = startOffset / 8;
                asciiEnd = asciiStart + (chunk_size / 8);
            },
        }

        // Print byte offset
        try pr.print("{x:0>8}: ", .{startOffset});

        // Pring the converted hex
        var j: usize = 0;
        while (j < chunk_size) : (j += container.wordSize) {
            try pr.print("{s} ", .{if (j + container.wordSize <= chunk_size) chunk[j..(j + container.wordSize)] else chunk[j..]});
        }

        // Print the associated ascii
        try pr.print(" ", .{});
        for (container.inputBuffer[asciiStart..asciiEnd]) |char| {
            if (ip(char)) {
                try pr.print("{c}", .{char});
            } else {
                try pr.print("", .{});
            }
        }
        try pr.print("\n", .{});

        // Update the position
        startOffset += chunk_size;
    }
}

fn processCommandLineArgs(args: *std.process.ArgIterator, container: *DataContainer) !void {
    while (args.next()) |arg| {
        if (eql(u8, arg, "--help") or eql(u8, arg, "-h")) {
            try pr.print("Usage: zxd [flags] [file]\n\n", .{});
            try pr.print("Flags:\n", .{});
            try pr.print("  -h, --help      Print this help message\n", .{});
            try pr.print("  -H, --hex       Print data in hexadecimal format (default)\n", .{});
            try pr.print("  -b, --binary    Print data in binary format\n", .{});
            try pr.print("  -f, --file      Read input from specified file\n", .{});
            try pr.print("  -l, --length    Specify number of bytes to read\n", .{});
            try pr.print("  -s, --start     Start reading from specified offset\n", .{});
            try pr.print("  -c, --per-line  Control the number of bytes per line\n", .{});
            std.process.exit(0);
        } else if (eql(u8, arg, "--hex") or eql(u8, arg, "-H")) {
            container.outputType = OutputType.hex;
            container.wordSize = 4;
            container.bytesPerLine = 32;
        } else if (eql(u8, arg, "--binary") or eql(u8, arg, "-b")) {
            container.outputType = OutputType.binary;
            container.wordSize = 8;
            container.bytesPerLine = 48;
        } else if (eql(u8, arg, "--file") or eql(u8, arg, "-f")) {
            openFile(args.next().?, container.allocator, &container.inputBuffer);
        } else if (eql(u8, arg, "--length") or eql(u8, arg, "-l")) {
            container.endOffset = std.fmt.parseInt(usize, args.next().?, 10) catch null;
        } else if (eql(u8, arg, "--start") or eql(u8, arg, "-s")) {
            container.startOffset = std.fmt.parseInt(u8, args.next().?, 10) catch 0;
        } else if (eql(u8, arg, "--per-line") or eql(u8, arg, "-c")) {
            container.bytesPerLine = std.fmt.parseInt(u8, args.next().?, 10) catch 32;
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

    var container: DataContainer = .{ .allocator = gpa.allocator() };
    defer container.deinit();

    try processCommandLineArgs(&args, &container);

    container.outputBuffer = switch (container.outputType) {
        OutputType.hex => try bytesToHex(container.inputBuffer, container.allocator),
        OutputType.binary => try bytesToBinary(container.inputBuffer, container.allocator),
    };

    try printOutputBuffer(container);
}
