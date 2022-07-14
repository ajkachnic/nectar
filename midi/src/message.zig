const std = @import("std");
const lib = @import("main.zig");

const Note = lib.Note;

const NoteInformation = struct { channel: Channel, note: lib.Note, velocity: Velocity };

pub const MidiMessage = union(enum) {
    /// This message is sent when a note is released (ended).
    NoteOff: NoteInformation,

    /// This message is sent when a note is depressed (start).
    NoteOn: NoteInformation,

    /// This message is most often sent by pressing down on the key after it "bottoms out".
    PolyphonicKeyPressure: NoteInformation,

    /// This message is sent when a controller value changes. Controllers include devices such as pedals and levers.
    ///
    /// Controller numbers 120-127 are reserved as "Channel Mode Messages".
    ControlChange: struct { channel: Channel, control_function: ControlFunction, control_value: ControlValue },

    /// This message is sent when the patch number changes.
    ProgramChange: struct { channel: Channel, program_number: ProgramNumber },

    /// This message is most often sent by pressing down on the key after it "bottoms out". This message is different
    /// from polyphonic after-touch. Use this message to send the single greatest pressure value (of all the current
    /// depressed keys).
    ChannelPressure: struct { channel: Channel, velocity: Velocity },

    /// This message is sent to indicate a change in the pitch bender (wheel or level, typically). The pitch bender is
    /// measured by a fourteen bit value. Center is 8192.
    PitchBendChange: struct { channel: Channel, pitch_bend: PitchBend },

    /// This message type allows manufacturers to create their own messages (such as bulk dumps, patch parameters, and
    /// other non-spec data) and provides a mechanism for creating additional MIDI Specification messages.
    ///
    /// In the data held by the SysEx message, the Manufacturer's ID code (assigned by MMA or AMEI) is either 1 byte or
    /// 3 bytes. Two of the 1 Byte IDs are reserved for extensions called Universal Exclusive Messages, which are not
    /// manufacturer-specific. If a device recognizes the ID code as its own (or as a supported Universal message) it
    /// will listen to the rest of the message. Otherwise the message will be ignored.
    SysEx: []const u8,

    /// MIDI Time Code Quarter Frame.
    ///
    /// The data is in the format 0nnndddd where nnn is the Message Type and dddd is the Value.
    ///
    /// TODO: Interpret data instead of providing the raw format.
    MidiTimeCode: u7,

    /// This is an internal 14 bit value that holds the number of MIDI beats (1 beat = six MIDI clocks) since the start
    /// of the song.
    SongPositionPointer: SongPosition,

    /// The Song Select specifies which sequence or song is to be played.
    SongSelect: Song,

    /// The u8 data holds the status byte.
    Reserved: u8,

    /// Upon receiving a Tune Request, all analog synthesizers should tune their oscillators.
    TuneRequest,

    /// Timing Clock. Sent 24 times per quarter note when synchronization is required.
    TimingClock,

    /// Start the current sequence playing. (This message will be followed with Timing Clocks).
    Start,

    /// Continue at the point the sequence was Stopped.
    Continue,

    /// Stop the current sequence.
    Stop,

    /// This message is intended to be sent repeatedly to tell the receiver that a connection is alive. Use of this
    /// message is optional. When initially received, the receiver will expect to receive another Active Sensing message
    /// each 300ms (max), and if it idoes not, then it will assume that the connection has been terminated. At
    /// termination, the receiver will turn off all voices and return to normal (non-active sensing) operation.
    ActiveSensing,

    /// Reset all receivers in the system to power-up status. This should be used sparingly, preferably under manual
    /// control. In particular, it should not be sent on power-up.
    Reset,

    pub fn bytes_size(self: *MidiMessage) usize {
        switch (self) {
            .NoteOff, .NoteOn, .PolyphonicKeyPressure, .ControlChange, .PitchBendChange, .SongPositionPointer => 3,
            .ProgramChange, .ChannelPressure, .MidiTimeCode, .SongSelect => 2,
            .SysEx => |b| 2 + b.len,
            .TuneRequest, .TimingClock, .Start, .Continue, .Stop, .ActiveSensing, .Reset => 1,
        }
    }

    /// The channel associated with the MIDI message, if applicable for the message type.
    pub fn channel(self: *MidiMessage) ?Channel {
        switch (self) {
            .NoteOff, .NoteOn, .PolyphonicKeyPressure => |n| n.channel,
            .ControlChange => |n| n.channel,
            .ProgramChange => |n| n.channel,
            .ChannelPressure => |n| n.channel,
            .PitchBendChange => |n| n.channel,
            else => null,
        }
    }

    pub const ParseError = error{
        NoBytes,
        UnexpectedDataByte,
        UnexpectedStatusByte,
        UnexpectedEndSysExByte,
        UnexpectedNonSysExEndByte,
        NoSysExEndByte,
        NotEnoughBytes,
    };

    pub fn parse(bytes: []const u8) ParseError!MidiMessage {
        if (bytes.len == 0) {
            return error.NoBytes;
        }
        if (!is_status_byte(bytes[0])) {
            return error.UnexpectedDataByte;
        }

        var chan = @intCast(Channel, bytes[0] & 0x0F);
        var data_a = if (bytes.len > 1) valid_data_byte(bytes[1]) else return error.NotEnoughBytes;
        var data_b = if (bytes.len > 2) valid_data_byte(bytes[2]) else return error.NotEnoughBytes;

        return switch (bytes[0] & 0xF0) {
            0x80 => .{
                .NoteOff = .{
                    .channel = chan,
                    .note = Note.from(try data_a),
                    .velocity = try data_b,
                },
            },
            0x90 => switch (try data_b) {
                0 => MidiMessage{
                    .NoteOff = .{
                        .channel = chan,
                        .note = lib.Note.from(try data_a),
                        .velocity = 0,
                    },
                },
                else => MidiMessage{
                    .NoteOn = .{
                        .channel = chan,
                        .note = lib.Note.from(try data_a),
                        .velocity = try data_b,
                    },
                },
            },
            0xA0 => .{
                .PolyphonicKeyPressure = .{
                    .channel = chan,
                    .note = lib.Note.from(try data_a),
                    .velocity = try data_b,
                },
            },
            0xB0 => .{
                .ControlChange = .{
                    .channel = chan,
                    .control_function = try data_a,
                    .control_value = try data_b,
                },
            },
            0xC0 => .{ .ProgramChange = .{ .channel = chan, .program_number = try data_a } },
            0xD0 => .{ .ChannelPressure = .{ .channel = chan, .velocity = try data_a } },
            0xE0 => .{
                .PitchBendChange = .{
                    .channel = chan,
                    .pitch_bend = combine_data(try data_a, try data_b),
                },
            },
            0xF0 => switch (bytes[0]) {
                0xF0 => MidiMessage.new_sysex(bytes),
                0xF1 => MidiMessage{ .MidiTimeCode = try data_a },
                0xF2 => MidiMessage{ .SongPositionPointer = combine_data(try data_a, try data_b) },
                0xF3 => MidiMessage{ .SongSelect = try data_a },
                0xF4, 0xF5 => MidiMessage{ .Reserved = bytes[0] },
                0xF6 => MidiMessage{ .TuneRequest = {} },
                0xF7 => error.UnexpectedEndSysExByte,
                0xF8 => MidiMessage{ .TimingClock = {} },
                0xF9 => MidiMessage{ .Reserved = bytes[0] },
                0xFA => MidiMessage{ .Start = {} },
                0xFB => MidiMessage{ .Continue = {} },
                0xFC => MidiMessage{ .Stop = {} },
                0xFD => MidiMessage{ .Reserved = bytes[0] },
                0xFE => MidiMessage{ .ActiveSensing = {} },
                0xFF => MidiMessage{ .Reset = {} },
                else => unreachable,
            },
            else => unreachable,
        };
    }

    fn new_sysex(bytes: []const u8) ParseError!MidiMessage {
        std.debug.assert(bytes[0] == 0xF0);

        var i: usize = 0;
        var end_i: ?usize = null;
        for (bytes[1..]) |b| {
            if (is_status_byte(b)) {
                end_i = i + 1;
                break;
            }
            i += 1;
        }

        if (end_i) |end| {
            if (bytes[end] != 0xF7) {
                return error.UnexpectedNonSysExEndByte;
            }
            return MidiMessage{ .SysEx = bytes[1..end] };
        } else {
            return error.NoSysExEndByte;
        }
    }
};

inline fn combine_data(lower: u7, higher: u7) u14 {
    return @intCast(u14, lower) + 128 * @intCast(u14, higher);
}

inline fn is_status_byte(b: u8) bool {
    return b & 0x80 == 0x80;
}

inline fn valid_data_byte(b: u8) MidiMessage.ParseError!u7 {
    if (b > 127) {
        return error.UnexpectedStatusByte;
    } else {
        return @intCast(u7, b);
    }
}

/// Specifies the velocity of an action (often key press, release, or aftertouch)
const Velocity = u7;

/// Specifies the value of a MIDI control.
pub const ControlValue = u7;

pub const ControlFunction = u7;

/// Specifies a program. Sometimes known as patch.
pub const ProgramNumber = u7;

/// A 14bit value specifying the pitch bend. Neutral is 8192.
pub const PitchBend = u14;

/// 14 bit value that holds the number of MIDI beats (1 beat = six MIDI clocks) since the start of the song.
pub const SongPosition = u14;

/// A song or sequence.
pub const Song = u7;

/// 16 channels, indexed from 0 to 15
const Channel = u4;

// test "Force evaluation" {
// }

test "Message.parse" {
    // no bytes produces an error
    try std.testing.expectError(error.NoBytes, MidiMessage.parse(&.{}));

    // no status byte produces an error
    try std.testing.expectError(error.UnexpectedDataByte, MidiMessage.parse(&.{0x00}));
}

test "Message.parse: NoteOff" {
    // NoteOff event produces errors with only 1 byte
    try std.testing.expectError(error.NotEnoughBytes, MidiMessage.parse(&.{0x84}));

    // NoteOff event produces errors with only 2 bytes
    try std.testing.expectError(error.NotEnoughBytes, MidiMessage.parse(&.{ 0x84, 64 }));

    // NoteOff event is decoded.
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0x84, 64, 100 }),
        .{ .NoteOff = .{
            .channel = 4,
            .note = Note.E4,
            .velocity = 100,
        } },
    );
}

test "Message.parse: NoteOn" {
    // NoteOn event produces errors with only 1 byte
    try std.testing.expectError(error.NotEnoughBytes, MidiMessage.parse(&.{0x94}));

    // NoteOn event produces errors with only 2 bytes
    try std.testing.expectError(error.NotEnoughBytes, MidiMessage.parse(&.{ 0x94, 64 }));

    // NoteOn event is decoded.
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0x94, 64, 100 }),
        .{ .NoteOn = .{
            .channel = 4,
            .note = Note.E4,
            .velocity = 100,
        } },
    );

    // NoteOn message with 0 velocity decodes as NoteOff
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0x94, 64, 0 }),
        .{ .NoteOff = .{
            .channel = 4,
            .note = Note.E4,
            .velocity = 0,
        } },
    );
}

test "Message.parse: SysEx" {
    // SysEx message is decoded with borrowed data
    try std.testing.expectEqualSlices(
        u8,
        (try MidiMessage.parse(&.{ 0xF0, 4, 8, 12, 16, 0xF7 })).SysEx,
        &.{ 4, 8, 12, 16 },
    );

    // SysEx message does not include bytes after the end byte
    try std.testing.expectEqualSlices(
        u8,
        (try MidiMessage.parse(&.{ 0xF0, 3, 6, 9, 12, 15, 0xF7, 125 })).SysEx,
        &.{ 3, 6, 9, 12, 15 },
    );

    // SysEx message without end status produces error
    try std.testing.expectError(
        error.NoSysExEndByte,
        MidiMessage.parse(&.{ 0xF0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }),
    );

    // SysEx message with wrong end byte produces error
    try std.testing.expectError(
        error.UnexpectedNonSysExEndByte,
        MidiMessage.parse(&.{ 0xF0, 1, 2, 3, 4, 5, 6, 7, 8, 0xF8 }),
    );
}

test "Message.parse: PitchBend" {
    // PitchBend with single byte produces error.
    try std.testing.expectError(error.NotEnoughBytes, MidiMessage.parse(&.{0xE4}));
    // PitchBend with only 2 bytes produces error.
    try std.testing.expectError(error.NotEnoughBytes, MidiMessage.parse(&.{ 0xE4, 64 }));
    // PitchBendChange is decoded.
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xE4, 64, 100 }),
        .{ .PitchBendChange = .{
            .channel = 4,
            .pitch_bend = 12864,
        } },
    );
}

test "Message.parse: PolyphonicKeyPressure" {
    // PolyphonicKeyPressure is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xA4, 64, 100 }),
        .{ .PolyphonicKeyPressure = .{
            .channel = 4,
            .note = Note.E4,
            .velocity = 100,
        } },
    );
}

test "Message.parse: ControlChange" {
    // ControlChange is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xB4, 64, 100 }),
        .{ .ControlChange = .{
            .channel = 4,
            .control_function = 64,
            .control_value = 100,
        } },
    );
}

test "Message.parse: ProgramChange" {
    // ProgramChange is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xC4, 64, 0 }),
        .{ .ProgramChange = .{ .channel = 4, .program_number = 64 } },
    );
}

test "Message.parse: ChannelPressure" {
    // ChannelPressure is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xD4, 64, 0 }),
        .{ .ChannelPressure = .{ .channel = 4, .velocity = 64 } },
    );
}

test "Message.parse: ChannelPressure" {
    // ChannelPressure is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xD4, 64, 0 }),
        .{ .ChannelPressure = .{ .channel = 4, .velocity = 64 } },
    );
}

test "Message.parse: misc decodes" {
    // MidiTimeCode is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF1, 8, 0 }),
        .{ .MidiTimeCode = 8 },
    );

    // SongPositionPointer is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF2, 14, 15 }),
        .{ .SongPositionPointer = combine_data(14, 15) },
    );

    // SongPositionSelect is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF3, 8, 0 }),
        .{ .SongSelect = 8 },
    );

    // Reserved is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF4, 0, 0 }),
        .{ .Reserved = 0xF4 },
    );

    // TuneRequest is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF6, 0, 0 }),
        .{ .TuneRequest = {} },
    );

    try std.testing.expectError(
        error.UnexpectedEndSysExByte,
        MidiMessage.parse(&.{ 0xF7, 0, 0 }),
    );

    // TimingClock is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF8, 0, 0 }),
        .{ .TimingClock = {} },
    );

    // Reserved is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xF9, 0, 0 }),
        .{ .Reserved = 0xF9 },
    );

    // Start is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xFA, 0, 0 }),
        .{ .Start = {} },
    );

    // Continue is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xFB, 0, 0 }),
        .{ .Continue = {} },
    );

    // Stop is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xFC, 0, 0 }),
        .{ .Stop = {} },
    );

    // Reserved is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xFD, 0, 0 }),
        .{ .Reserved = 0xFD },
    );

    // ActiveSensing is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xFE, 0, 0 }),
        .{ .ActiveSensing = {} },
    );

    // Reset is decoded
    try std.testing.expectEqual(
        MidiMessage.parse(&.{ 0xFF, 0, 0 }),
        .{ .Reset = {} },
    );
}
