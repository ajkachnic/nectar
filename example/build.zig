const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("example", "src/main.zig", .unversioned);
    lib.linkLibC();
    // const lib = b.addStaticLibrary("example", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const core = std.build.Pkg{
        .name = "nectar:core",
        .path = std.build.FileSource{ .path = "../core/src/main.zig" },
    };
    const vst2 = std.build.Pkg{
        .name = "nectar:vst2",
        .path = std.build.FileSource{ .path = "../vst2/src/main.zig" },
        .dependencies = &.{core},
    };
    const midi = std.build.Pkg{
        .name = "nectar:midi",
        .path = std.build.FileSource{ .path = "../midi/src/main.zig" },
        .dependencies = &.{core},
    };

    lib.addPackage(core);
    lib.addPackage(vst2);
    lib.addPackage(midi);

    // const main_tests = b.addTest("src/main.zig");
    // main_tests.setBuildMode(mode);

    // const test_step = b.step("test", "Run library tests");
    // test_step.dependOn(&main_tests.step);
}
