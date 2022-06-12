const std = @import("std");
const mem = std.mem;
const c = @import("c.zig");

pub fn serialize_imgui(variable: anytype, name: []const u8) void {
    const allocator = std.heap.page_allocator;
    const T = @TypeOf(variable);
    const type_name = @typeName(T);
    const c_type_name = allocator.dupeZ(u8, type_name) catch unreachable;
    defer allocator.free(c_type_name);
    const c_variable_name = allocator.dupeZ(u8, name) catch unreachable;
    defer allocator.free(c_variable_name);
    switch (@typeInfo(T)) {
        .ComptimeInt, .Int => {
            c.igText("%s:%s = %i", &c_variable_name[0], &c_type_name[0], @intCast(c_int, variable));
        },
        .Float => {
            var txt = std.fmt.allocPrintZ(allocator, "{s}:{s} = {d}", .{name, type_name, variable}) catch unreachable;
            defer allocator.free(txt);
            c.igText(txt);
            // Note: the code below shoes garbage values for the float type!
            // c.igText("%s:%s = %f", &c_variable_name[0], &c_type_name[0], variable);
        },
        .Void => {},
        .Bool => {
            c.igText("%s:%s = %s", &c_variable_name[0], &c_type_name[0], if (variable) "true" else "false");
        },
        .Optional => {
            if (variable) |v| {
                // TODO(hugo): member_name ??
                c.igIndent(1.0);
                serialize_imgui(v, "");
                c.igUnindent(1.0);
            } else {
                c.igText("%s:%s = null", &c_variable_name[0], &c_type_name[0]);
            }
        },
        .ErrorUnion => {},
        .ErrorSet => {},
        .Enum => {},
        .Union => {},
        .Struct => {
            if (c.igCollapsingHeader_TreeNodeFlags("Struct", 0)) {
                comptime var fields = std.meta.fields(T);
                inline for (fields) |field| {
                    c.igIndent(1.0);
                    serialize_imgui(@field(variable, field.name), field.name);
                    c.igUnindent(1.0);
                }
            }
        },
        .Pointer => {},
        .Array => {},
        .Fn => {},
        else => @compileError("Unable to serialize type'" ++ @typeName(T) ++ "'"),
    }
}
