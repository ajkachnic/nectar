const parameters = @import("./parameters.zig");
const plugin = @import("./plugin.zig");

pub const Parameters = parameters.Parameters;

pub const Plugin = plugin.Plugin;
pub const Info = plugin.Info;

pub const core = @import("nectar:core");
pub const midi = @import("nectar:midi");
pub const vst2 = @import("nectar:vst2");

pub const wrapper = struct {
    pub const vst2 = @import("wrapper/vst2.zig");
};
