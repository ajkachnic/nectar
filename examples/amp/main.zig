const std = @import("std");
const build_options = @import("build_options");
const nectar = @import("nectar");

const core = nectar.core;

pub const Parameters = nectar.Parameters(
    struct {
        const Self = @This();

        gain: f32 = 0.5,

        pub fn getParameterText(
            self: *Parameters,
            allocator: std.mem.Allocator,
            parameter: nectar.util.StructToEnum(Self),
        ) ?[]const u8 {
            return switch (parameter) {
                .gain => std.fmt.allocPrint(allocator, "{d:.2}", .{
                    (self.get("gain") - 0.5) * 2.0,
                }) catch null,
            };
        }

        pub fn getParameterName(
            self: *Parameters,
            allocator: std.mem.Allocator,
            parameter: nectar.util.StructToEnum(Self),
        ) ?[]const u8 {
            _ = self;
            _ = allocator;
            return switch (parameter) {
                .gain => "Gain",
            };
        }
    },
);

pub const Amplifier = struct {
    params: Parameters,

    sample_rate: f32 = 44100,
    allocator: std.mem.Allocator,

    pub fn create(
        into: *Amplifier,
        allocator: std.mem.Allocator,
    ) void {
        into.* = Amplifier.init(allocator);
    }

    pub fn deinit(self: *Amplifier) void {
        self.allocator.destroy(self);
    }

    pub fn init(allocator: std.mem.Allocator) Amplifier {
        return Amplifier{
            .allocator = allocator,
            .params = .{
                .params = .{},
            },
        };
    }

    pub fn process(self: *Amplifier, input: anytype, output: anytype) void {
        _ = self;
        var frame: usize = 0;
        var gain = self.params.get("gain") + 0.5;
        // const gain = 0.5;

        while (frame < output.frames) : (frame += 1) {
            // self.total_frames += 1;

            output.setFrame("Left", frame, input.getFrame("Left", frame) * gain);
            output.setFrame("Right", frame, input.getFrame("Right", frame) * gain);
        }
    }
};

pub const Plugin = nectar.Plugin(Amplifier, .{
    .unique_id = 83823493,
    .version = .{ 0, 0, 1, 0 },
    .name = "Example Zig VST",
    .vendor = "zig-vst",
    .initial_delay = 0,

    .features = &.{
        .effect,
    },

    .input = &[_]core.Channel{
        .{ .name = "Left" },
        .{ .name = "Right" },
    },
    .output = &[_]core.Channel{
        .{ .name = "Left" },
        .{ .name = "Right" },
    },
}, null);

comptime {
    switch (build_options.pluginType) {
        .vst2 => {
            const Vst2Plugin = nectar.wrapper.vst2.Wrap(Plugin);
            // usingnamespace Vst2Plugin.generateTopLevelHandlers();

            Vst2Plugin.generateExports({});
        },
    }
}
