---
sidebar_position: 5
---

# Wrapping Up the Plugin

We're almost done with our amplifier. The final step is declaring a `nectar.Plugin` and doing some cross-platform magic

## Declaring a `nectar.Plugin`

We can declare it like so:

```zig title="src/main.zig"
pub const Plugin = nectar.Plugin(Amplifier, .{
    .unique_id = 45395423,
    .version = .{ 0, 0, 1, 0 },
    .name = "Zig Amplify",
    .vendor = "nectar-examples",
    .initial_delay = 0,

    .features = &.{ .effect },

    .input = &[_]core.Channel{
        .{ .name = "Left" },
        .{ .name = "Right" },
    },
    .output = &[_]core.Channel{
        .{ .name = "Left" },
        .{ .name = "Right" },
    },
}, null);
```

Some quick notes:

- You're supposed to actually register your `unique_id`, but for testing, a good ol' random number will do just fine.
- The `features` array defines some of basic capabilties of a plugin. In this case, it's an effect plugin
- `input` and `output` are our IO layouts. If you were making a plugin which didn't take input (say a synth), you could just leave the input array empty

## Cross-Platform Stuff

This ties everything together. We're gonna generate unique code for each supported target, depending on what we declared in our `build.zig`:

```zig title="src/main.zig"
comptime {
    switch (build_options.pluginType) {
        .vst2 => {
            const Vst2Plugin = nectar.wrapper.vst2.Wrap(Plugin);

            Vst2Plugin.generateExports({});
        },
    }
}
```

:::tip

`nectar.wrapper` stores all the different wrappers for different plugin types. In most cases, it's a matter of calling `nectar.wrapper.name.Wrap(Plugin)` and then using that to generate the proper exports

:::

## Compiling

Now to build our plugin, we can run this shell command:

```shell
zig build vst2
```

And hopefully, it works!
