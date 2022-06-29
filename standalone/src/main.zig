const std = @import("std");
pub const c = @cImport({
    @cInclude("soundio/soundio.h");
});

comptime {
    _ = Backend;
    _ = Error;
    _ = Client;
}

test "Force analysis" {
    comptime {
        std.testing.refAllDecls(@This());
    }
}

pub const Backend = enum {
    None,
    Jack,
    PulseAudio,
    Alsa,
    CoreAudio,
    Wasapi,
    Dummy,

    pub inline fn convert(backend: Backend) c.SoundIoBackend {
        // TODO: Check if this can be done with @enumToInt
        switch (backend) {
            .None => c.SoundIoBackendNone,
            .Jack => c.SoundIoBackendJack,
            .PulseAudio => c.SoundIoBackendPulseAudio,
            .Alsa => c.SoundIoBackendAlsa,
            .CoreAudio => c.SoundIoBackendCoreAudio,
            .Wasapi => c.SoundIoBackendWasapi,
            .Dummy => c.SoundIoBackendWasapi,
        }
    }
};

pub const Error = error{
    Invalid,
} || std.mem.Allocator.Error;

pub const Client = struct {
    ptr: *c.SoundIo,

    /// Create a new client
    pub fn init() Client {
        var ptr = c.soundio_create().?;

        return Client{ .ptr = ptr };
    }

    /// Tries `connectBackend` on all available backends.
    pub fn connect(self: *Client) !void {
        switch (c.soundio_connect(self.ptr)) {
            c.SoundIoErrorInvalid => return error.Invalid,
            else => {},
        }
    }

    /// Attempts to connect to a specific backend
    pub fn connectBackend(self: *Client, backend: Backend) !void {
        switch (c.soundio_connect_backend(self.ptr, backend.convert())) {
            c.SoundIoErrorInvalid => return error.Invalid,
            else => {},
        }
    }
};
