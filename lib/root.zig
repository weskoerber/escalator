/// Restart your program with elevated privileges.
///
/// - If the program is already running as root (UID 0), this does nothing.
/// - If the program is not running as root but has root SUID permissions, this
///   function escalates permissions of the current procces.
/// - If the program is not running as root and does not have root SUID
///   permissions, this function spawns a child process as the root user using
///   the identity management tool `util` provided.
pub fn escalate(allocator: mem.Allocator, util: EscalationUtil) !void {
    switch (check()) {
        .root => {
            log.debug("already running as root", .{});
            return;
        },
        .suid => {
            log.debug("setuid(0)", .{});
            _ = linux.setuid(0);
            return;
        },
        .user => {
            log.debug("escalating privileges", .{});
        },
    }

    const args = try process.argsAlloc(allocator);
    defer allocator.free(args);

    const child_args = blk: {
        var args_list = std.ArrayList([]const u8).init(allocator);
        try args_list.append(util.path());
        try args_list.appendSlice(args);
        break :blk try args_list.toOwnedSlice();
    };
    defer allocator.free(child_args);

    var child = process.Child.init(child_args, allocator);
    const result = try child.spawnAndWait();
    switch (result) {
        .Exited => |code| process.exit(code),
        else => |x| {
            log.debug("unexpected signal from child: {}", .{x});
            process.exit(1);
        },
    }
}

/// Check to see who the current process is running as.
pub fn check() Identity {
    const uid = linux.getuid();
    const euid = linux.geteuid();

    if (uid == 0 and euid == 0) return .root;
    if (uid != 0 and euid == 0) return .suid;
    return .user;
}

/// A utility that manages user identities.
pub const EscalationUtil = enum {
    doas,
    sudo,

    /// Returns the path to the utility. Assumes utilities exist in `/usr/bin`.
    pub fn path(self: EscalationUtil) []const u8 {
        return switch (self) {
            .doas => "/usr/bin/doas",
            .sudo => "/usr/bin/sudo",
        };
    }
};

/// Identity of the current process.
pub const Identity = enum {
    /// The root user (UID 0).
    root,

    /// Not the root user, but has root SUID (SUID 0).
    suid,

    /// Running as a normal user (non-root).
    user,
};

const std = @import("std");
const debug = std.debug;
const heap = std.heap;
const linux = std.os.linux;
const mem = std.mem;
const posix = std.posix;
const process = std.process;

const log = std.log.scoped(.sudo);
