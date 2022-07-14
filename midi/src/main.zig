const std = @import("std");
// const testing = std.testing;

pub const message = @import("message.zig");
pub const note = @import("note.zig");

pub usingnamespace message;
pub usingnamespace note;

test "" {
    comptime std.testing.refAllDecls(@This());

    _ = message;
    _ = note;
}
