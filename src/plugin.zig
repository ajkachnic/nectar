const std = @import("std");
const nectar = @import("main.zig");

const trait = std.meta.trait;

const MidiMessage = nectar.midi.MidiMessage;

/// Plugin information
pub const Info = struct {
    unique_id: i32,

    version: [4]u8,

    name: []const u8 = "",
    vendor: []const u8 = "",

    initial_delay: usize = 0,
};

pub const Events = std.ArrayList(Event);
pub const Event = union(enum) {
    Midi: MidiMessage,
};

/// Plugin, with basic functionality. Used by wrappers to generate format specific code.
pub fn Plugin(
    comptime T: type,
    comptime info_arg: Info,
    comptime param_field: ?std.meta.FieldEnum(T),
) type {
    return struct {
        pub const info = info_arg;
        // TODO: Fix this really cursed bullshit
        pub const ParametersType = std.meta.fieldInfo(T, if (param_field) |f| f else .params).field_type;
        const Self = @This();

        inner: T,
        allocator: std.mem.Allocator,

        pub fn @"resume"(self: *Self) void {
            _ = self;
        }

        pub fn @"suspend"(self: *Self) void {
            _ = self;
        }

        pub fn setSampleRate(self: *Self, rate: f32) void {
            if (trait.hasFn("setSampleRate")(T)) {
                self.inner.setSampleRate(rate);
            }
        }

        pub fn setBufferSize(self: *Self, size: i64) void {
            if (trait.hasFn("setBufferSize")(T)) {
                self.inner.setBufferSize(size);
            }
        }

        pub fn processEvents(self: *Self, events: Events) void {
            for (events) |event| {
                switch (event) {
                    .Midi => |m| {
                        if (trait.hasFn("processMidiEvent")(T)) {
                            self.inner.processMidiEvent(m);
                        }
                    },
                }
            }
        }

        pub fn deinit(self: *Self) void {
            if (comptime trait.hasFn("deinit")(T)) {
                self.inner.deinit();
            }

            self.allocator.destroy(self);
        }
    };
}
