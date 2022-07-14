const std = @import("std");
const PluginType = enum {
    vst2,
};

// copied from latest zig std, not available in 0.9.1
pub fn tags(comptime T: type) *const [std.meta.fields(T).len]T {
    comptime {
        const fieldInfos = std.meta.fields(T);
        var res: [fieldInfos.len]T = undefined;
        for (fieldInfos) |field, i| {
            res[i] = @field(T, field.name);
        }
        return &res;
    }
}

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    // const lib = b.addSharedLibrary("amp", "main.zig", .unversioned);
    // lib.setBuildMode(mode);
    // lib.install();

    const nectar = std.build.Pkg{
        .name = "nectar",
        .path = .{ .path = "../../src/main.zig" },
        .dependencies = &.{
            .{ .name = "nectar:core", .path = .{ .path = "../../core/src/main.zig" } },
            .{ .name = "nectar:midi", .path = .{ .path = "../../midi/src/main.zig" } },
            .{ .name = "nectar:vst2", .path = .{ .path = "../../vst2/src/main.zig" } },
        },
    };

    for (tags(PluginType)) |tag| {
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
