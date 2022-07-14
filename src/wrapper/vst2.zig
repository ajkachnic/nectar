const std = @import("std");
const nectar = @import("../main.zig");

const trait = std.meta.trait;

const core = nectar.core;
const midi = nectar.midi;
const vst2 = nectar.vst2;
const api = vst2.api;

fn hasFeaure(haystack: []const nectar.Feature, needle: nectar.Feature) bool {
    return std.mem.indexOf(nectar.Feature, haystack, &.{needle}) != null;
}

/// Generate a VST2 Wrapper around a given `nectar.Plugin`
pub fn Wrap(comptime T: type) type {
    return struct {
        pub const Inner = T;

        pub const info = T.info;

        const Self = @This();

        inner: T,
        allocator: std.mem.Allocator,

        /// TODO: Remove the dummy argument once https://github.com/ziglang/zig/issues/5380 gets fixed
        pub fn generateExports(comptime dummy: void) void {
            _ = dummy;
            comptime std.debug.assert(@TypeOf(VSTPluginMain) == api.PluginMain);

            @export(VSTPluginMain, .{
                .name = "VSTPluginMain",
                .linkage = .Strong,
            });
        }

        fn VSTPluginMain(callback: api.HostCallback) callconv(.C) ?*api.AEffect {
            var allocator = std.heap.page_allocator;

            var embed_info = allocator.create(vst2.EmbedInfo) catch return null;
            embed_info.host_callback = callback;
            embed_info.effect = initAEffect();

            var self = init(allocator, embed_info) catch return null;
            _ = self;

            return &embed_info.effect;
        }

        fn initAEffect() api.AEffect {
            var flags = [2]api.Plugin.Flag{ .CanReplacing, undefined };
            var flagsSlice: []const api.Plugin.Flag = flags[0..1];
            if (hasFeaure(info.features, .instrument)) {
                flags[1] = .IsSynth;
                flagsSlice = flags[0..2];
            }
            return .{
                .dispatcher = dispatcherCallback,
                .setParameter = setParameterCallback,
                .getParameter = getParameterCallback,
                .processReplacing = processReplacingCallback,
                .processReplacingF64 = processReplacingCallbackF64,
                .num_programs = 0,
                .num_params = @intCast(i32, T.ParametersType.len()),
                .num_inputs = info.input.len,
                .num_outputs = info.output.len,
                .flags = api.Plugin.Flag.toBitmask(flagsSlice),
                // .flags = 0,
                .initial_delay = info.initial_delay,
                .unique_id = info.unique_id,
                .version = info.versionToInt(),
            };
        }

        fn init(allocator: std.mem.Allocator, embed_info: *vst2.EmbedInfo) !*Self {
            var self = try allocator.create(Self);
            embed_info.setCustomRef(self);

            self.allocator = allocator;

            var effect = &embed_info.effect;
            effect.dispatcher = dispatcherCallback;
            effect.setParameter = setParameterCallback;
            effect.getParameter = getParameterCallback;
            effect.processReplacing = processReplacingCallback;
            effect.processReplacingF64 = processReplacingCallbackF64;

            const type_info = @typeInfo(@TypeOf(T.create)).Fn;
            const returns_error = comptime trait.is(.ErrorUnion)(type_info.return_type.?);
            const takes_allocator = comptime blk_takes_allocator: {
                const args = type_info.args;
                break :blk_takes_allocator args.len == 2 and args[1].arg_type == std.mem.Allocator;
            };

            if (!takes_allocator and !returns_error) {
                T.create(&self.inner);
            } else if (takes_allocator and !returns_error) {
                T.create(&self.inner, allocator);
            } else if (!takes_allocator and returns_error) {
                try T.create(&self.inner);
            } else if (takes_allocator and returns_error) {
                try T.create(&self.inner, allocator);
            }

            return self;
        }

        fn deinit(self: *Self) void {
            // if (comptime trait.hasFn("deinit")(T)) {
            //     T.deinit(&self.inner);
            // }

            self.allocator.destroy(self);
        }

        fn fromEffectPtr(effect: *api.AEffect) ?*Self {
            const embed_info = @fieldParentPtr(vst2.EmbedInfo, "effect", effect);
            return embed_info.getCustomRef(Self);
        }

        // Dispatch events
        fn dispatcherCallback(effect: *api.AEffect, opcode: i32, index: i32, value: isize, ptr: ?*anyopaque, opt: f32) callconv(.C) isize {
            _ = index;
            _ = value;
            _ = opt;

            const self = fromEffectPtr(effect) orelse unreachable;
            const code = api.Codes.HostToPlugin.fromInt(opcode) catch return -1;

            switch (code) {
                .Initialize => {},
                .Shutdown => self.deinit(),
                .GetProductName => vst2.setData(ptr.?, info.name, api.ProductNameMaxLength),
                .GetVendorName => vst2.setData(ptr.?, info.vendor, api.VendorNameMaxLength),
                // .GetCategory => return info.category.toInt(i32),

                .GetParameterLabel => {
                    var params = self.inner.getParams();
                    var label = params.getParameterLabel(self.allocator, index);

                    if (label) |v| vst2.setData(ptr.?, v, api.ParamMaxLength);
                },
                .GetParameterDisplay => {
                    var params = self.inner.getParams();
                    var text = params.getParameterText(self.allocator, index);

                    if (text) |v| vst2.setData(ptr.?, v, api.ParamMaxLength);
                },
                .GetParameterName => {
                    var params = self.inner.getParams();
                    var name = params.getParameterName(self.allocator, index);

                    if (name) |v| vst2.setData(ptr.?, v, api.ParamMaxLength);
                },

                .GetCategory => return 0,
                .GetApiVersion => return 2400,
                .GetTailSize => return 0,
                .SetSampleRate => self.inner.setSampleRate(opt),
                .SetBufferSize => self.inner.setBufferSize(@intCast(i64, value)),
                .StateChange => {
                    if (value == 1) {
                        self.inner.@"resume"();
                    } else {
                        self.inner.@"suspend"();
                    }
                },
                .ProcessEvents => {
                    // if (std.meta.trait.hasFn("processEvents")(T)) {
                    var vst_events = @ptrCast(*api.VstEvents, @alignCast(@alignOf(api.VstEvents), ptr));
                    var events = blk: {
                        var list = nectar.Events.init(self.allocator);
                        var iter = vst_events.iter();
                        while (iter.next()) |_event| {
                            var event = api.Event.parse(_event);
                            var ev: ?nectar.Event = s: {
                                switch (event) {
                                    .Midi => |m| break :s .{
                                        .Midi = midi.MidiMessage.parse(&m.data) catch continue,
                                    },
                                    // else => break :s null,
                                }
                            };
                            if (ev) |e| list.append(e) catch {
                                std.log.warn("failed to allocate space for event list", .{});
                            };
                        }

                        break :blk list;
                    };
                    self.inner.processEvents(events);
                    defer events.deinit();
                    // }
                },
                // .GetInputInfo => {
                //     if (index >= 0 and index < info.inputs.len) {}
                // },
                .GetOutputInfo => {},
                else => {},
            }

            return 0;
        }

        fn setParameterCallback(effect: *api.AEffect, index: i32, parameter: f32) callconv(.C) void {
            const self = fromEffectPtr(effect) orelse return;
            self.inner.setParameter(index, parameter);
        }

        fn getParameterCallback(effect: *api.AEffect, index: i32) callconv(.C) f32 {
            const self = fromEffectPtr(effect) orelse return 0.0;
            return self.inner.getParameter(index);
        }

        fn processReplacingCallback(effect: *api.AEffect, inputs: [*][*]f32, outputs: [*][*]f32, sample_frames: i32) callconv(.C) void {
            const frames = @intCast(usize, sample_frames);

            var input = core.AudioBuffer(info.input, f32).fromRaw(inputs, frames);
            var output = core.AudioBuffer(info.output, f32).fromRaw(outputs, frames);

            const self = fromEffectPtr(effect) orelse return;
            self.inner.process(&input, &output);
        }

        fn processReplacingCallbackF64(effect: *api.AEffect, inputs: [*][*]f64, outputs: [*][*]f64, sample_frames: i32) callconv(.C) void {
            _ = effect;
            _ = inputs;
            _ = outputs;
            _ = sample_frames;
        }
    };
}
