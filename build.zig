const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();

    const coverage = b.option(bool, "test-coverage", "Generate test coverage") orelse false;

    const midi_tests = b.addTest("midi/src/main.zig");
    midi_tests.setBuildMode(mode);

    const cwd = std.fs.cwd();
    cwd.makeDir(".coverage") catch {};

    if (coverage) {
        midi_tests.setExecCmd(&.{
            "kcov",
            "--include-pattern=midi/src",
            ".coverage/midi",
            null,
        });
    }

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&midi_tests.step);
}
