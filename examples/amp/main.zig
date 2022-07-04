const std = @import("std");
const nectar = @import("nectar");

const build_options = @import("build_options");

pub const Parameters = nectar.Parameters(struct {
    gain: f32 = 1.0,
});

pub const Amplifier = struct {
    params: Parameters,

    pub fn init() Amplifier {
        return Amplifier{
            .params = .{},
        };
    }

    pub fn process(self: *Amplifier, input: anytype, output: anytype) void {
        var frame: usize = 0;
        var gain = self.params.get("gain");

        while (frame < output.frames) : (frame += 1) {
            self.total_frames += 1;

            output.setFrame("Left", frame, input.getFrame("Left") * gain);
            output.setFrame("Right", frame, input.getFrame("Right") * gain);
        }
    }
};

pub const Plugin = nectar.Plugin(Amplifier, .{
    .unique_id = 1000332,
});

comptime {
    switch (build_options.pluginType) {
        .vst2 => {
            const Vst2Plugin = nectar.wrapper.vst2.Wrap(Plugin);
            // usingnamespace Vst2Plugin.generateTopLevelHandlers();

            Vst2Plugin.generateExports({});
        },
    }
}
