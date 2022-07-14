const std = @import("std");
const testing = std.testing;

// export fn add(a: i32, b: i32) i32 {
//     return a + b;
// }

/// The Layout of an I/O Port
/// You cannot have two channels with the same name
/// in your layout.
pub const IOLayout = []const Channel;

/// Represents a single channel in the layout of a whole
/// I/O Port
pub const Channel = struct {
    pub const Arrangement = union(enum) {
        Custom: void,
        Empty: void,
        Mono: void,

        /// TODO
        Stereo: void,

        /// TODO
        Surround: void,
    };

    /// The name of this channel
    name: []const u8,

    short: ?[]const u8 = null,
    active: bool = true,
    arrangement: Arrangement = .{ .Mono = {} },
};

/// A Buffer contains data of the given I/O layout.
/// By using comptime features you can reference channels by their
/// specified name in your code. This is an easy way to provide
/// meaning without juggling constants.
pub fn AudioBuffer(comptime layout: IOLayout, comptime T: type) type {
    return struct {
        const Self = @This();

        pub const channel_count = layout.len;

        managed: bool,

        raw: [*][*]f32,
        frames: usize,

        pub fn init(allocator: std.mem.Allocator, frames: usize) !Self {
            var channels = std.ArrayList([*]f32).init(allocator);
            for (layout) |_| {
                var buffer: [*]f32 = (try allocator.alloc(f32, frames)).ptr;
                // buffer[frames] = null;
                try channels.append(buffer);
            }
            var raw = channels.toOwnedSlice().ptr;

            return Self{
                .managed = true,
                .raw = raw,
                .frames = frames,
            };
        }

        pub fn fromRaw(buffer_list: [*][*]T, frames: usize) Self {
            return Self{
                .raw = buffer_list,
                .frames = frames,
                .managed = false,
            };
        }

        fn getIndex(comptime name: []const u8) usize {
            return inline for (layout) |channel, i| {
                if (comptime std.mem.eql(u8, name, channel.name)) {
                    break i;
                }
            } else @compileError("Could not find channel with name '" ++ name ++ "'");
        }

        pub inline fn getBuffer(self: *Self, comptime name: []const u8) []f32 {
            const index = comptime getIndex(name);
            return self.raw[index][0..self.frames];
        }

        pub inline fn getConstBuffer(self: Self, comptime name: []const u8) []const f32 {
            const index = comptime getIndex(name);
            return self.raw[index][0..self.frames];
        }

        pub inline fn setFrame(self: *Self, comptime name: []const u8, frame: usize, value: T) void {
            const index = comptime getIndex(name);
            self.raw[index][frame] = value;
        }

        pub inline fn getFrame(self: Self, comptime name: []const u8, frame: usize) T {
            const index = comptime getIndex(name);
            return self.raw[index][frame];
        }

        pub inline fn setFrameByIndex(self: Self, index: usize, frame: usize, value: T) void {
            self.raw[index][frame] = value;
        }

        pub inline fn getFrameByIndex(self: Self, index: usize, frame: usize) T {
            return self.raw[index][frame];
        }
    };
}
