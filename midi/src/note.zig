const std = @import("std");

/// A midi note.
///
/// The format for the enum is `$NOTE` `$MODIFIER?` `$OCTAVE`. Note can be a note from `A` to `G`.
/// Modifier can be `b` for flat or `Sharp` for sharp. Octave is the number. The octave `-1` is
/// represented as `Minus1`.
pub const Note = enum(u7) {
    // Enharmonics
    pub const CSharpMinus1 = .DbMinus1;
    pub const DSharpMinus1 = .EbMinus1;
    pub const FSharpMinus1 = .GbMinus1;
    pub const GSharpMinus1 = .AbMinus1;
    pub const ASharpMinus1 = .BbMinus1;
    pub const CSharp0 = .Db0;
    pub const DSharp0 = .Eb0;
    pub const FSharp0 = .Gb0;
    pub const GSharp0 = .Ab0;
    pub const ASharp0 = .Bb0;
    pub const CSharp1 = .Db1;
    pub const DSharp1 = .Eb1;
    pub const FSharp1 = .Gb1;
    pub const GSharp1 = .Ab1;
    pub const ASharp1 = .Bb1;
    pub const CSharp2 = .Db2;
    pub const DSharp2 = .Eb2;
    pub const FSharp2 = .Gb2;
    pub const GSharp2 = .Ab2;
    pub const ASharp2 = .Bb2;
    pub const CSharp3 = .Db3;
    pub const DSharp3 = .Eb3;
    pub const FSharp3 = .Gb3;
    pub const GSharp3 = .Ab3;
    pub const ASharp3 = .Bb3;
    pub const CSharp4 = .Db4;
    pub const DSharp4 = .Eb4;
    pub const FSharp4 = .Gb4;
    pub const GSharp4 = .Ab4;
    pub const ASharp4 = .Bb4;
    pub const CSharp5 = .Db5;
    pub const DSharp5 = .Eb5;
    pub const FSharp5 = .Gb5;
    pub const GSharp5 = .Ab5;
    pub const ASharp5 = .Bb5;
    pub const CSharp6 = .Db6;
    pub const DSharp6 = .Eb6;
    pub const FSharp6 = .Gb6;
    pub const GSharp6 = .Ab6;
    pub const ASharp6 = .Bb6;
    pub const CSharp7 = .Db7;
    pub const DSharp7 = .Eb7;
    pub const FSharp7 = .Gb7;
    pub const GSharp7 = .Ab7;
    pub const ASharp7 = .Bb7;
    pub const CSharp8 = .Db8;
    pub const DSharp8 = .Eb8;
    pub const FSharp8 = .Gb8;
    pub const GSharp8 = .Ab8;
    pub const ASharp8 = .Bb8;
    pub const CSharp9 = .Db9;
    pub const DSharp9 = .Eb9;
    pub const FSharp9 = .Gb9;

    CMinus1 = 0,
    DbMinus1 = 1,
    DMinus1 = 2,
    EbMinus1 = 3,
    EMinus1 = 4,
    FMinus1 = 5,
    GbMinus1 = 6,
    GMinus1 = 7,
    AbMinus1 = 8,
    AMinus1 = 9,
    BbMinus1 = 10,
    BMinus1 = 11,
    C0 = 12,
    Db0 = 13,
    D0 = 14,
    Eb0 = 15,
    E0 = 16,
    F0 = 17,
    Gb0 = 18,
    G0 = 19,
    Ab0 = 20,
    A0 = 21,
    Bb0 = 22,
    B0 = 23,
    C1 = 24,
    Db1 = 25,
    D1 = 26,
    Eb1 = 27,
    E1 = 28,
    F1 = 29,
    Gb1 = 30,
    G1 = 31,
    Ab1 = 32,
    A1 = 33,
    Bb1 = 34,
    B1 = 35,
    C2 = 36,
    Db2 = 37,
    D2 = 38,
    Eb2 = 39,
    E2 = 40,
    F2 = 41,
    Gb2 = 42,
    G2 = 43,
    Ab2 = 44,
    A2 = 45,
    Bb2 = 46,
    B2 = 47,
    C3 = 48,
    Db3 = 49,
    D3 = 50,
    Eb3 = 51,
    E3 = 52,
    F3 = 53,
    Gb3 = 54,
    G3 = 55,
    Ab3 = 56,
    A3 = 57,
    Bb3 = 58,
    B3 = 59,
    /// Middle C.
    C4 = 60,
    Db4 = 61,
    D4 = 62,
    Eb4 = 63,
    E4 = 64,
    F4 = 65,
    Gb4 = 66,
    G4 = 67,
    Ab4 = 68,
    /// A440.
    A4 = 69,
    Bb4 = 70,
    B4 = 71,
    C5 = 72,
    Db5 = 73,
    D5 = 74,
    Eb5 = 75,
    E5 = 76,
    F5 = 77,
    Gb5 = 78,
    G5 = 79,
    Ab5 = 80,
    A5 = 81,
    Bb5 = 82,
    B5 = 83,
    C6 = 84,
    Db6 = 85,
    D6 = 86,
    Eb6 = 87,
    E6 = 88,
    F6 = 89,
    Gb6 = 90,
    G6 = 91,
    Ab6 = 92,
    A6 = 93,
    Bb6 = 94,
    B6 = 95,
    C7 = 96,
    Db7 = 97,
    D7 = 98,
    Eb7 = 99,
    E7 = 100,
    F7 = 101,
    Gb7 = 102,
    G7 = 103,
    Ab7 = 104,
    A7 = 105,
    Bb7 = 106,
    B7 = 107,
    C8 = 108,
    Db8 = 109,
    D8 = 110,
    Eb8 = 111,
    E8 = 112,
    F8 = 113,
    Gb8 = 114,
    G8 = 115,
    Ab8 = 116,
    A8 = 117,
    Bb8 = 118,
    B8 = 119,
    C9 = 120,
    Db9 = 121,
    D9 = 122,
    Eb9 = 123,
    E9 = 124,
    F9 = 125,
    Gb9 = 126,
    G9 = 127,

    pub fn from(note: u7) Note {
        return @intToEnum(Note, note);
    }

    // Creates a note from `u8`. `note` must be between [0, 127] inclusive to create a valid note.
    pub fn from_u8(note: u8) Note {
        return @intToEnum(Note, note);
    }

    // Creates a note from `u8`. Only the 7 least significant bits of `note` are used
    pub fn from_u8_lossy(note: u8) Note {
        return @intToEnum(Note, note & 0x7F);
    }

    /// The frequency using the standard 440Hz tuning.
    pub fn to_freq(self: Note, comptime T: type) T {
        var exp = (@intToFloat(T, @enumToInt(self)) + 36.376_316_562_295_91) / 12.0;

        return std.math.pow(T, 2, exp);
    }

    pub fn to_str(self: Note) []const u8 {
        switch (self) {
            .CMinus1 => "C-1",
            .DbMinus1 => "C#/Db-1",
            .DMinus1 => "D-1",
            .EbMinus1 => "D#/Eb-1",
            .EMinus1 => "E-1",
            .FMinus1 => "F-1",
            .GbMinus1 => "F#/Gb-1",
            .GMinus1 => "G-1",
            .AbMinus1 => "G#/Ab-1",
            .AMinus1 => "A-1",
            .BbMinus1 => "A#/Bb-1",
            .BMinus1 => "B-1",
            .C0 => "C0",
            .Db0 => "C#/Db0",
            .D0 => "D0",
            .Eb0 => "D#/Eb0",
            .E0 => "E0",
            .F0 => "F0",
            .Gb0 => "F#/Gb0",
            .G0 => "G0",
            .Ab0 => "G#/Ab0",
            .A0 => "A0",
            .Bb0 => "A#/Bb0",
            .B0 => "B0",
            .C1 => "C1",
            .Db1 => "C#/Db1",
            .D1 => "D1",
            .Eb1 => "D#/Eb1",
            .E1 => "E1",
            .F1 => "F1",
            .Gb1 => "F#/Gb1",
            .G1 => "G1",
            .Ab1 => "G#/Ab1",
            .A1 => "A1",
            .Bb1 => "A#/Bb1",
            .B1 => "B1",
            .C2 => "C2",
            .Db2 => "C#/Db2",
            .D2 => "D2",
            .Eb2 => "D#/Eb2",
            .E2 => "E2",
            .F2 => "F2",
            .Gb2 => "F#/Gb2",
            .G2 => "G2",
            .Ab2 => "G#/Ab2",
            .A2 => "A2",
            .Bb2 => "A#/Bb2",
            .B2 => "B2",
            .C3 => "C3",
            .Db3 => "C#/Db3",
            .D3 => "D3",
            .Eb3 => "D#/Eb3",
            .E3 => "E3",
            .F3 => "F3",
            .Gb3 => "F#/Gb3",
            .G3 => "G3",
            .Ab3 => "G#/Ab3",
            .A3 => "A3",
            .Bb3 => "A#/Bb3",
            .B3 => "B3",
            .C4 => "C4",
            .Db4 => "C#/Db4",
            .D4 => "D4",
            .Eb4 => "D#/Eb4",
            .E4 => "E4",
            .F4 => "F4",
            .Gb4 => "F#/Gb4",
            .G4 => "G4",
            .Ab4 => "G#/Ab4",
            .A4 => "A4",
            .Bb4 => "A#/Bb4",
            .B4 => "B4",
            .C5 => "C5",
            .Db5 => "C#/Db5",
            .D5 => "D5",
            .Eb5 => "D#/Eb5",
            .E5 => "E5",
            .F5 => "F5",
            .Gb5 => "F#/Gb5",
            .G5 => "G5",
            .Ab5 => "G#/Ab5",
            .A5 => "A5",
            .Bb5 => "A#/Bb5",
            .B5 => "B5",
            .C6 => "C6",
            .Db6 => "C#/Db6",
            .D6 => "D6",
            .Eb6 => "D#/Eb6",
            .E6 => "E6",
            .F6 => "F6",
            .Gb6 => "F#/Gb6",
            .G6 => "G6",
            .Ab6 => "G#/Ab6",
            .A6 => "A6",
            .Bb6 => "A#/Bb6",
            .B6 => "B6",
            .C7 => "C7",
            .Db7 => "C#/Db7",
            .D7 => "D7",
            .Eb7 => "D#/Eb7",
            .E7 => "E7",
            .F7 => "F7",
            .Gb7 => "F#/Gb7",
            .G7 => "G7",
            .Ab7 => "G#/Ab7",
            .A7 => "A7",
            .Bb7 => "A#/Bb7",
            .B7 => "B7",
            .C8 => "C8",
            .Db8 => "C#/Db8",
            .D8 => "D8",
            .Eb8 => "D#/Eb8",
            .E8 => "E8",
            .F8 => "F8",
            .Gb8 => "F#/Gb8",
            .G8 => "G8",
            .Ab8 => "G#/Ab8",
            .A8 => "A8",
            .Bb8 => "A#/Bb8",
            .B8 => "B8",
            .C9 => "C9",
            .Db9 => "C#/Db9",
            .D9 => "D9",
            .Eb9 => "D#/Eb9",
            .E9 => "E9",
            .F9 => "F9",
            .Gb9 => "F#/Gb9",
            .G9 => "G9",
        }
    }
};
