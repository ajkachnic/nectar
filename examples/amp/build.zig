const std = @import("std");
const PluginType = enum {
    vst2,
};

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    // const lib = b.addSharedLibrary("amp", "main.zig", .unversioned);
    // lib.setBuildMode(mode);
    // lib.install();

    const nectar = std.build.Pkg{
        .name = "nectar",
        .source = .{ .path = "../../src/main.zig" },
        .dependencies = &.{
            .{ .name = "nectar:core", .source = .{ .path = "../../core/src/main.zig" } },
            .{ .name = "nectar:midi", .source = .{ .path = "../../midi/src/main.zig" } },
            .{ .name = "nectar:vst2", .source = .{ .path = "../../vst2/src/main.zig" } },
        },
    };

    for (std.meta.tags(PluginType)) |tag| {
        const lib = b.addSharedLibrary("amp", "main.zig", .unversioned);
        lib.setBuildMode(mode);
        lib.install();

        lib.setOutputDir("zig-out");

        lib.addPackage(nectar);

        const options = b.addOptions();
        options.addOption(PluginType, "pluginType", tag);

        lib.addOptions("build_options", options);

        const cmd_step = b.step(@tagName(tag), "Build a " ++ @tagName(tag) ++ " plugin");
        cmd_step.dependOn(&lib.step);
    }
}
