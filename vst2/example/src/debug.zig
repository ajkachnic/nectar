const std = @import("std");

pub fn startDebugger(allocator: std.mem.Allocator) !void {
    _ = allocator;
    var pid = std.os.linux.getpid();

    std.log.info("process id: {}", .{pid});

    // if (try std.os.fork() == 0) {z
    // } else {p

    // }

    // const debugger_command = try std.fmt.allocPrint(allocator, "lldb -p {}", .{pid});
    // var child_process = try std.ChildProcess.init(&.{
    //     "alacritty",
    //     "-e",
    //     debugger_command,
    //     "&",
    // }, allocator);
    // try child_process.spawn();
}
