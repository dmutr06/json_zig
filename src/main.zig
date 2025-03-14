const std = @import("std");

const json = @import("json_zig_lib");

fn print_json_value(val: json.JsonValue) void {
    switch (val) {
        .null => std.debug.print("null", .{}),
        .string => |str| std.debug.print("\"{s}\"", .{str}),
        .number => |num| std.debug.print("{d}", .{num}),
        .boolean => |b| std.debug.print("{}", .{b}),
        .array => |arr| {
            std.debug.print("[", .{});
            for (0..arr.items.len - 1) |idx| {
                print_json_value(arr.items[idx]);
                std.debug.print(", ", .{});
            }
            print_json_value(arr.getLast());
            std.debug.print("]", .{});
        },
        .object => |obj| {
            std.debug.print("{{\n", .{});
            var iter = obj.iterator();
            while (iter.next()) |kv| {
                std.debug.print("  {s}: ", .{kv.key_ptr.*});
                print_json_value(kv.value_ptr.*);
                std.debug.print(",\n", .{});
            }
            std.debug.print("}}", .{});
        },
    }
}

pub fn main() !void {
    const result = try json.parse("{ \"hi\": 2.5, \"yoo\": [1, \"hello!\", null], \"itWorks\": true }");

    print_json_value(result);
    std.debug.print("\n", .{});
}
