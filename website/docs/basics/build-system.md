---
sidebar_position: 2
---

# Configuring the Build System

Nectar ~~exploits~~ leverages Zig's flexible build system[^1] to allow for great cross-platform support.

To start configuring, we want to create an enum of all the plugin formats we're targetting:

```zig title="build.zig"
const PluginType = enum {
  // More formats coming soon
  vst2,
};
```

Then, we want to add nectar as a package:

```zig title="build.zig"
pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const nectar = std.build.Pkg{
        .name = "nectar",
        .source = .{ .path = "libs/nectar/src/main.zig" },
        .dependencies = &.{
            .{ .name = "nectar:core", .source = .{ .path = "libs/nectar/core/src/main.zig" } },
            .{ .name = "nectar:midi", .source = .{ .path = "libs/nectar/midi/src/main.zig" } },
            .{ .name = "nectar:vst2", .source = .{ .path = "libs/nectar/vst2/src/main.zig" } },
        },
    };

    // snip
}
```

:::info

In a *coming-soon* version, adding this package will become significantly easier (I'm just still working out the details)

:::

After adding the package, we want to iterate through all of our plugin targets. In Zig, we can use `std.meta.tags()` to get every tag value of an enum. Using that function, we can setup up all of our targets:

```zig title="build.zig"
pub fn build(b: *std.build.Builder) void {
    // snip (after defining nectar)
    for (std.meta.tags(PluginType)) |tag| {
        const lib = b.addSharedLibrary(
          "name-" ++ @tagName(tag),
          "main.zig",
          .unversioned,
        );

        lib.setBuildMode(mode);
        lib.install();

        lib.addPackage(nectar);

        const options = b.addOptions();
        options.addOption(PluginType, "pluginType", tag);

        lib.addOptions("build_options", options);

        const cmd_step = b.step(@tagName(tag), "Build a " ++ @tagName(tag) ++ " plugin");
        cmd_step.dependOn(&lib.step);
    }
}
```

In one foul swoop, we generate a build target for every target that we support.

:::note tip

That little `lib.addOptions()` call uses some *zig magic* to create a package of options dynamically, and then make them available under the name `build_options`

Later on, we're going to use these options to do some conditional compilation (converting our generic Plugin wrapper to a format specific one). This setup is *really cursed* and probably not permanent; But it's how we do it for now, so just roll with it.

:::

[^1]: Fear not, it also *exploits* many other Zig tools, like comptime and metaprogramming
