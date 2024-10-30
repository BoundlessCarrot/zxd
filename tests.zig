const std = @import("std");

// test "bytesToHex" {
//     const allocator = std.testing.allocator;
//     const input = "Hello World";
//     const expected = "48656c6c6f20576f726c64";
//
//     const result = try bytesToHex(input, allocator);
//     defer allocator.free(result);
//
//     try std.testing.expectEqualStrings(expected, result);
// }

// test "start offset basic usage" {
//     const allocator = std.testing.allocator;
//
//     var args = try std.process.argsWithAllocator(allocator);
//     defer args.deinit();
//
//     args += [_][]const u8{ "zxd", "-s", "6", "-f", "test.txt" };
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args.skip();
//     try processCommandLineArgs(&args, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     // defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("576f726c64", container.outputBuffer[0..10]);
// }

// test "start offset beyond input length" {
//     const allocator = std.testing.allocator;
//
//     var args = try std.process.argsWithAllocator(allocator);
//     defer args.deinit();
//
//     try args.appendSlice(&[_][]const u8{ "zxd", "-s", "100", "-f", "test.txt" });
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args.skip();
//     try processCommandLineArgs(&args, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     // defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("", container.outputBuffer);
// }

// test "start offset negative value" {
//     const allocator = std.testing.allocator;
//
//     var args = std.ArrayList([]const u8).init(allocator);
//     defer args.deinit();
//
//     try args.appendSlice(&[_][]const u8{ "zxd", "-s", "-1", "-f", "test.txt" });
//
//     var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator, args.items);
//     defer args_iterator.deinit();
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args_iterator.skip();
//     try processCommandLineArgs(&args_iterator, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("48656c6c6f20576f726c64", container.outputBuffer);
// }
//
// test "length basic usage" {
//     const allocator = std.testing.allocator;
//
//     var args = std.ArrayList([]const u8).init(allocator);
//     defer args.deinit();
//
//     try args.appendSlice(&[_][]const u8{ "zxd", "-l", "5", "-f", "test.txt" });
//
//     var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator, args.items);
//     defer args_iterator.deinit();
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args_iterator.skip();
//     try processCommandLineArgs(&args_iterator, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("48656c6c6f", container.outputBuffer[0..10]);
// }
//
// test "length zero value" {
//     const allocator = std.testing.allocator;
//
//     var args = std.ArrayList([]const u8).init(allocator);
//     defer args.deinit();
//
//     try args.appendSlice(&[_][]const u8{ "zxd", "-l", "0", "-f", "test.txt" });
//
//     var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator, args.items);
//     defer args_iterator.deinit();
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args_iterator.skip();
//     try processCommandLineArgs(&args_iterator, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("", container.outputBuffer);
// }
//
// test "length negative value" {
//     const allocator = std.testing.allocator;
//
//     var args = std.ArrayList([]const u8).init(allocator);
//     defer args.deinit();
//
//     try args.appendSlice(&[_][]const u8{ "zxd", "-l", "-1", "-f", "test.txt" });
//
//     var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator, args.items);
//     defer args_iterator.deinit();
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args_iterator.skip();
//     try processCommandLineArgs(&args_iterator, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("", container.outputBuffer);
// }
//
// test "length beyond input" {
//     const allocator = std.testing.allocator;
//
//     var args = std.ArrayList([]const u8).init(allocator);
//     defer args.deinit();
//
//     try args.appendSlice(&[_][]const u8{ "zxd", "-l", "1000", "-f", "test.txt" });
//
//     var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator, args.items);
//     defer args_iterator.deinit();
//
//     var container = DataContainer{
//         .allocator = allocator,
//         .inputBuffer = "Hello World",
//     };
//     defer container.deinit();
//
//     _ = args_iterator.skip();
//     try processCommandLineArgs(&args_iterator, &container);
//
//     container.outputBuffer = try bytesToHex(container.inputBuffer, container.allocator);
//     defer allocator.free(container.outputBuffer);
//
//     try std.testing.expectEqualStrings("48656c6c6f20576f726c64", container.outputBuffer);
// }
