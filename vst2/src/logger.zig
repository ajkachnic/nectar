const std = @import("std");
const api = @import("api.zig");
const EmbedInfo = @import("main.zig").EmbedInfo;

var log_file: ?std.fs.File = null;
var log_allocator = std.heap.page_allocator;

// var log_file_path = "/home/andrew/.log/nectar.log";

pub fn initLogger() bool {
    const cwd = std.fs.cwd();
    log_file = cwd.createFile("nectar.log", .{}) catch return false;
    return true;
}

pub const LoggerFn = fn (
    ptr: [*]u8,
    len: usize,
) void;

pub fn externalWriteLog(ptr: [*]u8, len: usize) void {
    var data: []u8 = undefined;
    data.ptr = ptr;
    data.len = len;
    std.debug.print("{s}", .{data});

    if (log_file) |file| {
        file.writeAll(data) catch return;
    }
}
