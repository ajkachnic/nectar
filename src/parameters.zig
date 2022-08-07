const std = @import("std");

const Atomic = std.atomic.Atomic;

pub const util = struct {
    pub fn StructToEnum(comptime T: type) type {
        const fields = std.meta.fieldNames(T);
        var names: [fields.len]std.builtin.TypeInfo.EnumField = undefined;

        var i: usize = 0;
        inline for (fields) |field| {
            names[i] = .{ .name = field, .value = i };
            i += 1;
        }

        return @Type(.{
            .Enum = std.builtin.TypeInfo.Enum{
                .layout = .Auto,
                .tag_type = std.meta.Int(.unsigned, std.math.sqrt(fields.len)),
                .fields = &names,
                .decls = &.{},
                .is_exhaustive = true,
            },
        });
    }

    fn getFunction(comptime name: []const u8, FnT: type, ImplT: type) ?FnT {
        // Find the candidate in the implementation type.
        for (std.meta.declarations(ImplT)) |decl| {
            if (std.mem.eql(u8, name, decl.name)) {
                return @field(ImplT, name);
            }
        }

        return null;
    }
};

pub fn Parameters(comptime Params: type) type {
    const info = @typeInfo(Params).Struct;
    var fields: [info.fields.len]std.builtin.TypeInfo.StructField = undefined;

    var i: usize = 0;
    inline for (info.fields) |field| {
        var updated_field = field;
        // TODO: Check for floats only (or whatever is supported)
        // TODO: Support nested parameters
        updated_field.field_type = Atomic(field.field_type);
        if (field.default_value) |default| {
            var _default = @ptrCast(*const field.field_type, default).*;
            updated_field.default_value = &Atomic(field.field_type).init(_default);
        }
        fields[i] = updated_field;

        i += 1;
    }

    const updated_info = std.builtin.TypeInfo{
        .Struct = .{
            .layout = .Auto,
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        },
    };

    return struct {
        const Self = @This();

        const GetParameterInfoFn = fn (
            self: *Self,
            std.mem.Allocator,
            tag: util.StructToEnum(Params),
        ) ?[]const u8;

        params: @Type(updated_info),

        const getParameterNameFn = util.getFunction("getParameterName", GetParameterInfoFn, Params);
        const getParameterTextFn = util.getFunction("getParameterText", GetParameterInfoFn, Params);
        const getParameterLabelFn = util.getFunction("getParameterLabel", GetParameterInfoFn, Params);

        pub fn setParameter(self: *Self, param: i32, value: f32) void {
            var j: i32 = 0;
            inline for (info.fields) |field| {
                if (j == param) {
                    @field(self.params, field.name).store(value, .Unordered);
                    break;
                }
                j += 1;
            }
        }

        pub fn getParameter(self: *Self, param: i32) f32 {
            var j: i32 = 0;
            inline for (info.fields) |field| {
                if (j == param) {
                    return @field(self.params, field.name).load(.Unordered);
                }
                j += 1;
            }
            return 0.0;
        }

        pub fn getParameterName(self: *Self, allocator: std.mem.Allocator, param: i32) ?[]const u8 {
            if (getParameterNameFn) |getParam| {
                const E = util.StructToEnum(Params);
                var tag = @intToEnum(E, param);

                return getParam(self, allocator, tag);
            }
            return null;
        }

        pub fn getParameterText(self: *Self, allocator: std.mem.Allocator, param: i32) ?[]const u8 {
            if (getParameterTextFn) |getParam| {
                const E = util.StructToEnum(Params);
                var tag = @intToEnum(E, param);
                // var tag = std.meta.intToEnum(E, param);

                return getParam(self, allocator, tag);
            }
            return null;
        }

        pub fn getParameterLabel(self: *Self, allocator: std.mem.Allocator, param: i32) ?[]const u8 {
            if (getParameterLabelFn) |getParam| {
                const E = util.StructToEnum(Params);
                var tag = @intToEnum(E, param);

                return getParam(self, allocator, tag);
            }
            return null;
        }

        pub fn get(self: *Self, comptime name: []const u8) f32 {
            return @field(self.params, name).load(.Unordered);
        }

        pub fn set(self: *Self, comptime name: []const u8, value: f32) void {
            return @field(self.params, name).store(value, .Unordered);
        }

        pub inline fn len() usize {
            return info.fields.len;
        }
    };
}
