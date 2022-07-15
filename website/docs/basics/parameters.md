---
sidebar_position: 3
---

# Defining our Parameters

Parameters are shared-values between plugin and host.

Let's start our by opening up the `src/main.zig` file, and emptying it. Then we want to write in our imports:

```zig title="src/main.zig"
const std = @import("std");
const nectar = @import("nectar");
const build_options = @import("build_options");

const core = nectar.core; // One of the nectar modules
```

This is where we see our first bit of *zig magic* take shape. That `build_options` package is our dynamically created package. Beyond that, nothing about this code is really special or unique.

But now, we can define our parameters, shared-values between the Plugin and it's Host. For this guide, we're building a simple amplifier, so we only want one parameter: the gain value to multiply by.

```zig title="src/main.zig"
pub const Parameters = nectar.Parameters(
    struct {
        gain: f32 = 0.5,
    }
);

// snip
```

:::note

We define `gain` to have a default value of `0.5` for one main reason: depending on the plugin format, the minimum and maximums for a parameter are different. But, VST2 has a range of 0 to 1, so we target that middle value. We can then multiply by two to get our "true" gain range of 0 to 2.

Little limitations like this are useful to keep in mind while developing your plugin. In the future, there might be a way to define parameter ranges and have nectar manage these inconsistencies itself. But until then, we need to do things like this.

:::

This is the bare minimum to define parameters; We pass a struct of our parameters and their defaults to `nectar.Parameters`, which generates a thread-safe (hopefully) wrapper around them. And this is great, but since this plugin won't have a GUI, we need the parameter to be labeled. Otherwise, it'll just be a knob with no other information.

So we can replace the old code with this to get some labels:

```zig title="src/main.zig"
pub const Parameters = nectar.Parameters(
    struct {
        const Self = @This();

        gain: f32 = 0.5,

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

// snip
```

If that feels like quite a jump, it's okay. We're gonna break this code down:

- `getParameterName` is like a method in an OOP language: it will automatically be called when needed if present, and has a default if it's not present
- We do the `_ = self;` and similar because Zig will complain about unused variables otherwise. You can delete those if you use those variables
- We return the result of switching over a give parameter

:::tip

`nectar.util.StructToEnum` takes a struct and returns an enum of all of it's fields. It's mostly used for parameter based logic, since otherwise, we would need to give each parameter an index and use that everywhere (which would be very error prone).

:::

There are a few more methods that you can specify similar to `getParameterName`, like:

- `getParameterText`: Get the display text for a parameter (ex. we could convert gain to decibels and display it like that)
- `getParameterLabel`: Get the format/label for a parameter (ex. `dB`, `Hz`, `%`, etc)

They all share the same defintion type, and work similarly; You can read more about parameters [here](/docs/api/parameters)
