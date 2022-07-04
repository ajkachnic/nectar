const std = @import("std");

const Atomic = std.atomic.Atomic;

pub fn Parameters(comptime params: type) type {
    var info = @typeInfo(params).Struct;

    var i: usize = 0;
    inline for (info.fields) |field| {
        var updated_field = field;
        // TODO: Check for floats only (or whatever is supported)
        // TODO: Support nested parameters
        updated_field.field_type = Atomic(field.field_type);
        if (field.default_value) |default| {
            updated_field.default_value = &Atomic(field.field_type).init(default.*);
        }
        info.fields[i] = updated_field;

        i += 1;
    }

    const patched_info = info;

    const Methods = struct {
        const Self = @This();

        pub fn setParameter(self: *Self, param: i32, value: f32) void {
            @field(self, patched_info.fields[param].name).store(value, .Unordered);
        }

        pub fn getParameter(self: *Self, param: i32) f32 {
            return @field(self, patched_info.fields[param].name).load(.Unordered);
        }

        pub fn get(self: *Self, comptime name: []const u8) f32 {
            return @field(self, name).load(.Unordered);
        }

        pub fn set(self: *Self, comptime name: []const u8, value: f32) void {
            return @field(self, name).store(value, .Unordered);
        }

        pub inline fn len() usize {
            return patched_info.fields.len;
        }
    };

    var methods_info = @typeInfo(Methods);

    info.decls = methods_info.decls;

    return @Type(info);
}
