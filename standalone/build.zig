const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const docs = b.addTest("src/main.zig");
    docs.linkLibC();
    docs.linkSystemLibrary("soundio");
    docs.setBuildMode(mode);
    docs.emit_docs = .emit;

    const docs_step = b.step("docs", "Generate docs");
    docs_step.dependOn(&docs.step);
}
