---
sidebar_position: 4
---

# Defining our Plugin

Since we have our parameters set up, we now want to declare our main interface with nectar: Our plugin struct

```zig title="src/main.zig"
// snip

pub const Amplifier = struct {
    params: Parameters,
    allocator: std.mem.Allocator,

    pub fn create(into: *Amplifier, allocator: std.mem.Allocator) void {
        into.* = Amplifier.init(allocator);
    }

    pub fn init(allocator: std.mem.Allocator) Amplifier {
        return Amplifier{
            .allocator = allocator,
            .params = .{
                .params = .{},
            },
        };
    }

    pub fn deinit(self: *Amplifier) void {
        // We would want to deallocate any used resources here
        _ = self;
    }
};
```

This lays the groundwork of our plugin, but we're missing one crucial feature: the actual audio processing. We can do this by defining a function called `process` inside `Amplifier`:

```zig title="src/main.zig"
pub const Amplifier = struct {
    // snip

    pub fn process(self: *Amplifier, input: anytype, output: anytype) void {
        var frame: usize = 0;
        var gain = self.params.get("gain") * 2;

        while (frame < output.frames) : (frame += 1) {
            output.setFrame("Left", frame, input.getFrame("Left", frame) * gain);
            output.setFrame("Right", frame, input.getFrame("Right", frame) * gain);
        }
    }
};
```

This lets us process audio, but it still leaves some questions:

- What are the types of `input` and `output`?
- What is all this `setFrame`/`getFrame` magic?

## Introducing `AudioBuffer`

`input` and `output` are both `AudioBuffer`s. The type `AudioBuffer` comes from `nectar.core.AudioBuffer`, and the concept is ~~stolen~~ *borrowed* from [zig-vst](https://github.com/schroffl/zig-vst/blob/03d97dc048ed7f53bdcd36838b6767c73359e261/src/audio_io.zig#L35-L79).

Although the implementation can be scary, the actual concept is simple. An AudioBuffer takes an I/O layout (basically a list of channels and their names and format) and lets you reference this layout by name. So, instead of having to use magic numbers to get a channel, they're easily accessible.

:::tip

When dealing with named channels, things like capitalization and trailing spaces matter. Watch out, and always check your names and references (this bit me in the ass at least a couple times while writing examples). But the difference between juggling names and juggling magic numbers is that the names are compile-time errors, and the numbers are logic errors.

:::

For now, just take it for granted that our layout will have two channels ("Left" and "Right") and each is mono. In the next guide, we'll define our I/O layout and finish up our plugin.
