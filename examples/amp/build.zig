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

        lib.addPackage(nectar);

        const options = b.addOptions();
        options.addOption(PluginType, "pluginType", tag);

        lib.addOptions("build_options", options);

        const cmd_step = b.step(@tagName(tag), "Build a " ++ @tagName(tag) ++ " plugin");
        cmd_step.dependOn(&lib.step);
    }

    // const vst2_lib = b.addSharedLibrary("amp", "main.zig", .unversioned);
    // vst2_lib.setBuildMode(mode);
    // vst2_lib.install();

    // var vst2 = b.step("vst2", "Build a VST2.4 plugin");
    // vst2.dependOn(&vst2_lib.step);

    // var build_vst2 = nectar.buildVst2(b, "amp", "main.zig", mode);
    // var vst2 = b.step("vst2", "Build a VST2.4 plugin");
    // vst2.dependOn(&build_vst2.step);

    // var build_clap = nectar.buildClap(b, "amp", "main.zig", mode);
    // var clap = b.step("clap", "Build a CLAP plugin");
    // clap.dependOn(build_clap.step);

    // var build_standalone = nectar.buildStandalone(b, "amp", "main.zig", mode);
    // var standalone = b.step("standalone", "Build a standalone application");
    // standalone.dependOn(build_standalone.step);
}
