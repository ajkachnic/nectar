const std = @import("std");
const nectar = @import("main.zig");

const trait = std.meta.trait;

const MidiMessage = nectar.midi.MidiMessage;

pub const Feature = enum {
    /// Produce audio from note events
    instrument,
    /// Audio effect
    effect,
    /// Note generator/sequencer
    generator,
    analyzer,

    mixing,
    mastering,
};

/// Plugin information
pub const Info = struct {
    unique_id: i32,

    version: [4]u8,

    name: []const u8 = "",
    vendor: []const u8 = "",

    initial_delay: usize = 0,

    features: []const Feature,

    input: nectar.core.IOLayout,
    output: nectar.core.IOLayout,

    pub fn versionToInt(self: Info) i32 {
        const v = self.version;

        return (@as(i32, v[0]) << 24) | (@as(i32, v[1]) << 16) | (@as(i32, v[2]) << 8) | @as(i32, v[3]);
    }
};

pub const Events = std.ArrayList(Event);
pub const Event = union(enum) {
    Midi: MidiMessage,
};

/// Plugin, with basic functionality. Used by wrappers to generate format specific code.
pub fn Plugin(
    comptime T: type,
    comptime info_arg: Info,
    comptime _param_field: ?std.meta.FieldEnum(T),
) type {
    return struct {
        pub const info = info_arg;
        pub const param_field = if (_param_field) |f| f else .params;
        // TODO: Fix this really cursed bullshit
        pub const ParametersType = std.meta.fieldInfo(T, param_field).field_type;
        const Self = @This();

        inner: T,
        allocator: std.mem.Allocator,

        pub inline fn getParams(self: *Self) ParametersType {
            return @field(self.inner, @tagName(param_field));
        }

        pub fn create(into: *Self, allocator: std.mem.Allocator) void {
            into.allocator = allocator;

            const type_info = @typeInfo(@TypeOf(T.create)).Fn;
            const returns_error = comptime trait.is(.ErrorUnion)(type_info.return_type.?);
            const takes_allocator = comptime blk_takes_allocator: {
                const args = type_info.args;
                break :blk_takes_allocator args.len == 2 and args[1].arg_type == std.mem.Allocator;
            };

            if (!takes_allocator and !returns_error) {
                T.create(&into.inner);
            } else if (takes_allocator and !returns_error) {
                T.create(&into.inner, allocator);
            } else if (!takes_allocator and returns_error) {
                try T.create(&into.inner);
            } else if (takes_allocator and returns_error) {
                try T.create(&into.inner, allocator);
            }
        }

        pub fn @"resume"(self: *Self) void {
            _ = self;
        }

        pub fn @"suspend"(self: *Self) void {
            _ = self;
        }

        pub fn setSampleRate(self: *Self, rate: f32) void {
            _ = rate;
            if (comptime trait.hasFn("setSampleRate")(T)) {
                self.inner.setSampleRate(rate);
            }
        }

        pub fn setBufferSize(self: *Self, size: i64) void {
            _ = size;
            if (comptime trait.hasFn("setBufferSize")(T)) {
                self.inner.setBufferSize(size);
            }
        }

        pub fn setParameter(self: *Self, index: i32, value: f32) void {
            @field(self.inner, @tagName(param_field)).setParameter(index, value);
        }

        pub fn getParameter(self: *Self, index: i32) f32 {
            return @field(self.inner, @tagName(param_field)).getParameter(index);
        }

        pub fn processEvents(self: *Self, events: Events) void {
            for (events.items) |event| {
                switch (event) {
                    .Midi => |m| {
                        if (comptime trait.hasFn("processMidiEvent")(T)) {
                            self.inner.processMidiEvent(m);
                        }
                    },
                }
            }
        }

        pub fn process(self: *Self, input: *nectar.core.AudioBuffer(info.input, f32), output: *nectar.core.AudioBuffer(info.output, f32)) void {
            _ = input;
            _ = output;

            if (comptime trait.hasFn("process")(T)) {
                self.inner.process(input, output);
            }
        }

        pub fn deinit(self: *Self) void {
            if (comptime trait.hasFn("deinit")(T)) {
                T.deinit(&self.inner);
            }

            self.allocator.destroy(self);
        }
    };
}
