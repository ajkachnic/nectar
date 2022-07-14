const std = @import("std");
const testing = std.testing;

/// Used with VST API to pass plugin info around.
pub const AEffect = extern struct {
    pub const Magic: i32 = ('V' << 24) | ('s' << 16) | ('t' << 8) | 'P';

    /// Magic numbers!
    magic: i32 = Magic,
    /// Host to plugin dispatcher
    dispatcher: DispatcherCallback,

    /// Deprecated in VST 2.4
    deprecated_process: ProcessCallback = deprecatedProcessCallback,

    /// Set value of automatable parameter.
    setParameter: SetParameterCallback,

    /// Get value of automatable parameter.
    getParameter: GetParameterCallback,

    /// Number of programs (Presets)
    num_programs: i32,

    /// Number of parameters. ALl prorgams are assumed to have this many parameters
    num_params: i32,

    /// Number of audio inputs.
    num_inputs: i32,

    /// Number of audio outputs.
    num_outputs: i32,

    /// Bitmask made up of values from `api.Plugin.Flags`
    flags: i32,

    /// Rserved for host, must be 0
    reserved1: isize = 0,

    /// Rserved for host, must be 0
    reserved2: isize = 0,

    /// For algorithms which need input in the first place (group delay or latency in samples).
    ///
    /// This value should be initially in a resume state.
    initial_delay: i32,

    // Deprecated unused member
    _real_qualities: i32 = 0,

    // Deprecated unused member
    _off_qualities: i32 = 0,

    // Deprecated unused member
    _io_ratio: i32 = 0,

    /// Void pointer usable by api to store object data
    object: ?*anyopaque = null,

    /// User defined pointer
    user: ?*anyopaque = null,

    /// Registered unique identifier (register it at Steinberg 3rd part support Web)
    /// This is used to identify a plugin during save/load of preset and project.
    unique_id: i32,

    /// Plugin version (ex. 1100 for v1.1.0.0)
    version: i32,

    /// Processs audio samples in replacing mode
    processReplacing: ProcessCallback,

    /// Processs double-audio samples in replacing mode
    processReplacingF64: ProcessCallbackF64,

    /// Reserved for future use
    future: [56]u8 = [_]u8{0} ** 56,

    fn deprecatedProcessCallback(effect: *AEffect, inputs: [*][*]f32, outputs: [*][*]f32, sample_frames: i32) callconv(.C) void {
        _ = effect;
        _ = inputs;
        _ = outputs;
        _ = sample_frames;
    }
};

test "AEffect" {
    try testing.expectEqual(@as(i32, 0x56737450), AEffect.Magic);
}

pub const Codes = struct {
    // TODO: Add all opcodes (https://github.com/RustAudio/vst-rs/blob/master/src/plugin.rs)
    pub const HostToPlugin = enum(i32) {
        /// Called when plugin is initialized.
        Initialize = 0,

        /// Called when plugin is being shut down.
        Shutdown = 1,

        /// [value]: preset number to change to.
        ChangePreset = 2,
        /// [return]: current preset number.
        GetCurrentPresetNum = 3,
        /// [ptr]: char array with new preset name, limited to `consts::MAX_PRESET_NAME_LEN`.
        SetCurrentPresetName = 4,
        /// [ptr]: char buffer for current preset name, limited to `consts::MAX_PRESET_NAME_LEN`.
        GetCurrentPresetName = 5,

        /// [index]: parameter
        /// [ptr]: char buffer, limited to `consts.MAX_PARAM_STR_LEN` (e.g. "db", "ms", etc)
        GetParameterLabel = 6,
        /// [index]: parameter
        /// [ptr]: char buffer, limited to `consts.MAX_PARAM_STR_LEN` (e.g. "0.5", "ROOM", etc).
        GetParameterDisplay = 7,
        /// [index]: parameter
        /// [ptr]: char buffer, limited to `consts.MAX_PARAM_STR_LEN` (e.g. "Release", "Gain")
        GetParameterName = 8,

        /// Deprecated.
        _GetVu = 9,

        /// [opt]: new sample rate.
        SetSampleRate = 10,
        /// [value]: new maximum block size.
        SetBufferSize = 11,
        /// [value]: 1 when plugin enabled, 0 when disabled.
        StateChange = 12,

        /// [ptr]: Rect** receiving pointer to editor size.
        EditorGetRect = 13,
        /// [ptr]: system dependent window pointer
        EditorOpen = 14,
        /// Close editor, no arguments.
        EditorClose = 15,

        GetProductName = 48,
        GetVendorName = 47,
        GetInputInfo = 33,
        GetOutputInfo = 34,
        GetCategory = 35,
        GetTailSize = 52,
        GetApiVersion = 58,
        GetMidiInputs = 78,
        GetMidiOutputs = 79,
        GetMidiKeyName = 66,
        StartProcess = 71,
        StopProcess = 72,
        GetPresetName = 29,
        CanDo = 51,
        GetVendorVersion = 49,
        GetEffectName = 45,
        CanBeAutomated = 26,
        EditorIdle = 19,
        EditorKeyDown = 59,
        EditorKeyUp = 60,
        ProcessEvents = 25,

        pub fn toInt(self: HostToPlugin) i32 {
            return @enumToInt(self);
        }

        pub fn fromInt(int: anytype) !HostToPlugin {
            return std.meta.intToEnum(HostToPlugin, int);
        }
    };

    pub const PluginToHost = enum(i32) {
        /// [return]: host vst version (ex 2400 for VST 2.4)
        GetVersion = 1,
        /// Notifies the host that the input/output setup has changed.
        /// This can allow the host to check num_inputs/num_outputs or call `getSpeakerArrangement()`
        /// [return]: 1 if supported.
        IOChanged = 13,

        GetSampleRate = 16,
        GetBufferSize = 17,
        GetVendorString = 32,

        pub fn toInt(self: PluginToHost) i32 {
            return @enumToInt(self);
        }

        pub fn fromInt(int: anytype) !PluginToHost {
            return std.meta.intToEnum(HostToPlugin, int);
        }
    };
};

pub const HighLevelCode = union(enum(i32)) {
    Initialize: void = 0,
    SetSampleRate: f32 = 10,
    SetBufferSize: isize = 11,

    EditorGetRect: *?*Rect = 13,
    EditorOpen: void = 14,
    EditorClose: void = 15,

    ProcessEvents: *const VstEvents = 25,
    GetPresetName: [*:0]u8 = 29,
    GetCategory: void = 35,

    GetVendorName: [*:0]u8 = 47,
    GetProductName: [*:0]u8 = 48,

    GetTailSize: void = 52,
    GetApiVersion: void = 58,

    pub fn parseOpCode(opcode: i32) ?std.meta.Tag(HighLevelCode) {
        const T = std.meta.Tag(HighLevelCode);
        return std.meta.intToEnum(T, opcode) catch return null;
    }

    pub fn parse(
        opcode: i32,
        index: i32,
        value: isize,
        ptr: ?*anyopaque,
        opt: f32,
    ) ?HighLevelCode {
        _ = index;
        const code = HighLevelCode.parseOpCode(opcode) orelse return null;

        return switch (code) {
            .SetSampleRate => .{ .SetSampleRate = opt },
            .SetBufferSize => .{ .SetBufferSize = value },

            .EditorGetRect => .{ .EditorGetRect = @ptrCast(*?*Rect, @alignCast(@alignOf(*?*Rect), ptr)) },
            .EditorOpen => .{ .EditorOpen = {} },
            .EditorClose => .{ .EditorClose = {} },

            .ProcessEvents => .{ .ProcessEvents = @ptrCast(*VstEvents, @alignCast(@alignOf(VstEvents), ptr)) },

            .GetPresetName => .{ .GetPresetName = @ptrCast([*:0]u8, ptr) },

            .GetCategory => .{ .GetCategory = {} },

            .GetVendorName => .{ .GetVendorName = @ptrCast([*:0]u8, ptr) },
            .GetProductName => .{ .GetProductName = @ptrCast([*:0]u8, ptr) },

            .GetApiVersion => .{ .GetApiVersion = {} },

            else => return null,
        };
    }
};

pub const VstEvents = struct {
    num_events: i32,
    reserved: *isize,
    events: [*]VstEvent,

    pub fn iter(self: *const VstEvents) Iterator {
        return .{ .index = 0, .ptr = self };
    }

    pub const Iterator = struct {
        index: usize,
        ptr: *const VstEvents,

        pub fn next(self: *Iterator) ?VstEvent {
            if (self.index >= self.ptr.num_events) {
                return null;
            }

            const ev = self.ptr.events[self.index];
            self.index += 1;
            return ev;
        }
    };
};

pub const VstEvent = struct {
    pub const Type = enum(u8) {
        midi = 1,
        audio = 2,
        video = 3,
        parameter = 4,
        trigger = 5,
        sysex = 6,
    };

    typ: Type,
    byte_size: i32,
    delta_frames: i32,
    flags: i32,
    data: [16]u8,
};

pub const Event = union(enum) {
    Midi: struct {
        flags: i32,
        note_length: i32,
        note_offset: i32,
        data: [4]u8,
        detune: i8,
        note_off_velocity: u8,
    },

    pub fn parse(event: VstEvent) Event {
        switch (event.typ) {
            .midi => {
                const raw = @ptrCast(*const RawVstMidiEvent, &event);

                return Event{ .Midi = .{
                    .flags = raw.flags,
                    .note_length = raw.note_length,
                    .note_offset = raw.note_offset,
                    .data = raw.midi_data,
                    .detune = raw.detune,
                    .note_off_velocity = raw.note_off_velocity,
                } };
            },
            .sysex => unreachable, // TODO
            else => unreachable,
        }
    }
};

pub const RawVstMidiEvent = struct {
    typ: VstEvent.Type,
    byte_size: i32,
    delta_frames: i32,
    flags: i32,
    note_length: i32,
    note_offset: i32,
    midi_data: [4]u8,
    detune: i8,
    note_off_velocity: u8,
    reserved: [2]u8,
};

pub const Plugin = struct {
    // pub const Flags = struct {
    //     /// Plugin has an editor.
    //     has_editor: bool = false,
    //     /// Plugin can process 32 bit audio. (Mandatory in VST 2.4)
    //     can_replacing: bool = true,
    //     /// Plugin preset data is handled in formatless chunks.
    //     program_chunks: bool = false,
    //     /// Plugin is a synth.
    //     is_synth: bool = false,
    //     /// Plugin does not produce sound when al input is silence.
    //     no_sound_in_stop: bool = false,
    //     /// Supports 64 bit audio processing
    //     can_double_replacing: bool = false,

    //     pub fn toBitmask(self: Flags) i32 {
    //         var result: i32 = 0;

    //         if (self.has_editor) result = result | 1;
    //         if (self.can_replacing) result = result | 1 << 4;
    //         if (self.program_chunks) result = result | 1 << 5;
    //         if (self.is_synth) result = result | 1 << 8;
    //         if (self.no_sound_in_stop) result = result | 1 << 9;
    //         if (self.can_double_replacing) result = result | 1 << 12;

    //         return result;
    //     }
    // };
    pub const Flag = enum(i32) {
        /// Plugin has an editor.
        HasEditor = 1,
        /// Plugin can process 32 bit audio. (Mandatory in VST 2.4)
        CanReplacing = 1 << 4,
        /// Plugin preset data is handled in formatless chunks.
        ProgramChunks = 1 << 5,
        /// Plugin is a synth.
        IsSynth = 1 << 8,
        /// Plugin does not produce sound when al input is silence.
        NoSoundInStop = 1 << 9,
        /// Supports 64 bit audio processing
        CanDoubleReplacing = 1 << 12,

        pub fn toInt(self: Flag, comptime Int: type) Int {
            return @intCast(Int, @enumToInt(self));
        }

        pub fn toBitmask(flags: []const Flag) i32 {
            var result: i32 = 0;

            for (flags) |flag| {
                result = result | flag.toInt(i32);
            }

            return result;
        }
    };

    pub const Category = enum {
        Unknown,
        Effect,
        Synthesizer,
        Analysis,
        Mastering,
        Spacializer,
        RoomFx,
        SurroundFx,
        Restoration,
        OfflineProcess,
        Shell,
        Generator,

        pub fn toInt(self: Category, comptime Int: type) Int {
            return @intCast(Int, @enumToInt(self));
        }
    };
};

pub const Rect = extern struct {
    top: i16,
    left: i16,
    bottom: i16,
    right: i16,
};

pub const ProductNameMaxLength = 64;
pub const VendorNameMaxLength = 64;
pub const ParamMaxLength = 32;

pub const PluginMain = fn (
    callback: HostCallback,
) callconv(.C) ?*AEffect;

/// Host callback function passed to plugin.
/// Can be used to query host information from plugin side.
pub const HostCallback = fn (
    effect: *AEffect,
    opcode: i32,
    index: i32,
    value: isize,
    ptr: ?*anyopaque,
    opt: f32,
) callconv(.C) isize;

/// Dispatcher function used to process opcodes. Called by host.
pub const DispatcherCallback = fn (
    effect: *AEffect,
    opcode: i32,
    index: i32,
    value: isize,
    ptr: ?*anyopaque,
    opt: f32,
) callconv(.C) isize;

/// Process function used to process 32-bit floating point samples. Called by host.
pub const ProcessCallback = fn (
    effect: *AEffect,
    inputs: [*][*]f32,
    outputs: [*][*]f32,
    sample_frames: i32,
) callconv(.C) void;

/// Process function used to process 64-bit floating point samples. Called by host.
pub const ProcessCallbackF64 = fn (
    effect: *AEffect,
    inputs: [*][*]f64,
    outputs: [*][*]f64,
    sample_frames: i32,
) callconv(.C) void;

/// Callback function used to set parameter values. Called by host.
pub const SetParameterCallback = fn (
    effect: *AEffect,
    index: i32,
    parameter: f32,
) callconv(.C) void;

/// Callback function used to get parameter values. Called by host.
pub const GetParameterCallback = fn (
    effect: *AEffect,
    index: i32,
) callconv(.C) f32;
