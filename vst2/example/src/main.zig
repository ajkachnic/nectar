const std = @import("std");
const core = @import("nectar:core");
const vst2 = @import("nectar:vst2");
const midi = @import("nectar:midi");

const startDebugger = @import("debug.zig").startDebugger;

const SineOscillator = struct {
    const Self = @This();

    current_angle: f32 = 0.0,
    angle_delta: f32 = 0.0,

    fn setFrequency(self: *Self, frequency: f32, sample_rate: f32) void {
        var cycles_per_sample = frequency / sample_rate;
        self.angle_delta = cycles_per_sample * 2.0 * std.math.pi;
    }

    inline fn getNextSample(self: *Self) f32 {
        var current_sample = std.math.sin(self.current_angle);
        self.updateAngle();
        return current_sample;
    }

    inline fn updateAngle(self: *Self) void {
        self.current_angle += self.angle_delta;
        if (self.current_angle >= 2.0 * std.math.pi) {
            self.current_angle -= 2.0 * std.math.pi;
        }
    }
};

const WavetableOscillator = struct {
    const Self = @This();

    current_index: f32 = 0.0,
    table_delta: f32 = 0.0,
    table_size: usize,
    wavetable: MonoAudioBuffer,

    pub fn init(wavetable: MonoAudioBuffer) Self {
        return Self{
            .wavetable = wavetable,
            .table_size = wavetable.frames - 2,
        };
    }

    fn setFrequency(self: *Self, frequency: f32, sample_rate: f32) void {
        var table_size_over_sample_rate = @intToFloat(f32, self.table_size) / sample_rate;
        self.table_delta = frequency * table_size_over_sample_rate;
    }

    inline fn getNextSample(self: *Self) f32 {
        var index0 = @floatToInt(usize, std.math.round(self.current_index));
        var index1 = index0 + 1;

        var frac = self.current_index - @intToFloat(f32, index0);

        var table = self.wavetable.getConstBuffer("Mono");
        var value0 = table[index0];
        var value1 = table[index1];

        var current_sample = value0 + frac * (value1 - value0);

        self.current_index += self.table_delta;
        if (self.current_index > @intToFloat(f32, self.table_size)) {
            self.current_index -= @intToFloat(f32, self.table_size);
        }

        return current_sample;
    }
};

const MonoAudioBuffer = core.AudioBuffer(&[_]core.Channel{
    .{ .name = "Mono" },
}, f32);

const Synth = struct {
    total_frames: usize = 0,
    notes: std.EnumSet(midi.Note),

    table_size: u8 = 1 << 7,
    level: f32 = 0.0,

    root_allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,

    sine_table: MonoAudioBuffer,
    oscillators: std.ArrayListUnmanaged(*WavetableOscillator),

    pub fn create(into: *Synth, allocator: std.mem.Allocator) void {
        into.* = Synth.init(allocator);
        var alloc = into.allocator;
        startDebugger(alloc) catch {
            std.log.err("Failed to start debugger", .{});
        };

        var num_oscillators: u8 = 128;
        var i: u8 = 0;
        while (i < num_oscillators) : (i += 1) {
            var oscillator = alloc.create(WavetableOscillator) catch {
                std.log.err("Failed to allocate oscillator", .{});
                std.os.exit(1);
            };
            oscillator.* = WavetableOscillator.init(into.sine_table);

            var frequency = midi.Note.from_u8_lossy(i).to_freq(f32);

            oscillator.setFrequency(frequency, 44100);
            into.oscillators.append(alloc, oscillator) catch {
                std.log.err("Failed to allocate oscillators", .{});
                std.os.exit(1);
            };
        }
        into.level = 0.25 / @intToFloat(f32, 2);
    }

    pub fn init(allocator: std.mem.Allocator) Synth {
        var arena = std.heap.ArenaAllocator.init(allocator);
        std.log.err("initing\n", .{});
        var synth = Synth{
            .allocator = arena.allocator(),
            .arena = arena,
            .root_allocator = allocator,
            .notes = .{},
            .oscillators = .{},
            .sine_table = undefined,
        };
        synth.createWavetable();
        return synth;
    }

    pub fn deinit(self: *Synth) void {
        self.arena.deinit();
    }

    fn createWavetable(self: *Synth) void {
        std.log.err("creating wavetable\n", .{});

        self.sine_table = MonoAudioBuffer.init(self.allocator, self.table_size + 1) catch {
            std.log.err("Failed to allocate sine table", .{});
            std.os.exit(1);
        };

        var samples = self.sine_table.getBuffer("Mono");

        var harmonics = [_]u8{ 1, 3, 5, 6, 7, 9, 13, 15 };
        var harmonic_weights = [_]f32{ 0.5, 0.1, 0.05, 0.125, 0.09, 0.005, 0.002, 0.001 };

        comptime std.debug.assert(harmonics.len == harmonic_weights.len);

        std.log.err("still creating wavetable\n", .{});

        var i: usize = 0;
        for (harmonics) |harmonic| {
            var angle_delta: f32 = (std.math.pi * 2.0) / @intToFloat(f32, self.table_size - 1 * harmonic);
            var current_angle: f32 = 0.0;

            var j: usize = 0;
            while (j < self.table_size) : (j += 1) {
                var sample = std.math.sin(current_angle);
                samples[i] += sample * harmonic_weights[i];
                current_angle += angle_delta;
            }

            i += 1;
        }

        samples[self.table_size] = samples[0];
        std.log.err("done creating wavetable...\n", .{});
    }

    pub fn process(self: *Synth, input: anytype, output: anytype) void {
        _ = input;
        var frame: usize = 0;

        while (frame < output.frames) : (frame += 1) {
            var signal: f32 = 0;
            var i: u8 = 0;
            for (self.oscillators.items) |oscillator| {
                std.log.err("oscillator: {}\n", .{i});
                if (self.notes.contains(midi.Note.from_u8_lossy(i))) {
                    var sample = oscillator.getNextSample();
                    // std.log.err("note contained", .{});
                    signal += sample * self.level;
                }
                i += 1;
            }
            // self.total_frames += 1;
            // const t = @intToFloat(f32, self.total_frames) / 44100;

            // var signal: ?f32 = null;

            // var iter = self.notes.iterator();
            // var num_notes: usize = 0;

            // while (iter.next()) |note| {
            //     std.log.debug("iter {}", .{iter});
            //     var freq = note.to_freq(f32);
            //     if (signal) |s| {
            //         signal = s + sin(freq, t);
            //     } else {
            //         signal = sin(freq, t);
            //     }
            //     num_notes += 1;
            // }
            if (signal >= 0.0) {
                output.setFrame("Left", frame, signal);
                output.setFrame("Right", frame, signal);
            }
        }
    }

    pub fn processEvents(self: *Synth, events: *vst2.api.VstEvents) void {
        var iter = events.iter();
        while (iter.next()) |_event| {
            var event = vst2.api.Event.parse(_event);
            switch (event) {
                .Midi => |m| {
                    var parsed = midi.MidiMessage.parse(&m.data) catch unreachable;
                    switch (parsed) {
                        .NoteOn => |n| {
                            self.notes.setPresent(n.note, true);
                        },
                        .NoteOff => |n| {
                            self.notes.setPresent(n.note, false);
                        },
                        else => {},
                    }
                },
            }
        }
    }

    fn sin(freq: f32, t: f32) f32 {
        return std.math.sin(t * std.math.pi * 2.0 * freq);
    }
};

const Plugin = vst2.VstPlugin(.{
    .unique_id = 0x30d98,
    .version = .{ 0, 0, 1, 0 },
    .name = "Example Zig VST",
    .vendor = "zig-vst",
    .initial_delay = 0,
    .flags = &[_]vst2.api.Plugin.Flag{ .IsSynth, .CanReplacing },
    .category = .Synthesizer,

    .input = &[_]core.Channel{},
    .output = &[_]core.Channel{
        .{ .name = "Left" },
        .{ .name = "Right" },
    },
}, Synth);

pub usingnamespace Plugin.generateTopLevelHandlers();

comptime {
    Plugin.generateExports({});
}
