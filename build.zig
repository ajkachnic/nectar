const std = @import("std");

// pub fn buildVst2(
//     b: *std.build.Builder,
//     name: []const u8,
//     main_file: []const u8,
//     mode: ?std.builtin.Mode,
// ) *std.build.LibExeObjStep {
//     const nectar = std.build.Pkg{
//         .name = "nectar",
//         .source = std.build.FileSource{ .path = "./nectar/src/main.zig" },
//     };

//     const options = b.addOptions();
//     options.addOption([]const u8, "real_path", main_file);

//     var lib = b.addSharedLibrary(name, "./nectar/build/vst2.zig", .unversioned);
//     lib.addPackage(nectar);
//     lib.addOptions("options", options);
//     if (mode) |m| lib.setBuildMode(m);

//     return lib;
// }

// pub fn build(b: *std.build.Builder) void {
//     // Standard release options allow the person running `zig build` to select
//     // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
//     const mode = b.standardReleaseOptions();

//     const lib = b.addStaticLibrary("nectar", "src/main.zig");
//     lib.setBuildMode(mode);
//     lib.install();

//     const main_tests = b.addTest("src/main.zig");
//     main_tests.setBuildMode(mode);

//     const test_step = b.step("test", "Run library tests");
//     test_step.dependOn(&main_tests.step);
// }
