pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try escalator.escalate(allocator, .sudo);

    debug.print("My UID: {d}\n", .{std.os.linux.getuid()});
}

const std = @import("std");
const debug = std.debug;
const heap = std.heap;
const process = std.process;

const escalator = @import("escalator");
