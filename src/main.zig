const parameters = @import("./parameters.zig");
const plugin = @import("./plugin.zig");

usingnamespace plugin;
usingnamespace parameters;

pub const core = @import("nectar:core");
pub const midi = @import("nectar:midi");
pub const vst2 = @import("nectar:vst2");

pub const wrapper = struct {
    pub const vst2 = @import("wrapper/vst2.zig");
};
