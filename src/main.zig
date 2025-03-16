const std = @import("std");

const json = @import("json_zig_lib");

fn print_json_value(val: json.JsonValue, ident: usize) void {
    switch (val) {
        .null => std.debug.print("null", .{}),
        .string => |str| std.debug.print("\"{s}\"", .{str}),
        .number => |num| std.debug.print("{d}", .{num}),
        .boolean => |b| std.debug.print("{}", .{b}),
        .array => |arr| {
            std.debug.print("[", .{});
            for (0..arr.items.len - 1) |idx| {
                print_json_value(arr.items[idx], ident);
                std.debug.print(", ", .{});
            }
            print_json_value(arr.getLast(), ident);
            std.debug.print("]", .{});
        },
        .object => |obj| {
            std.debug.print("{{\n", .{});
            var iter = obj.iterator();
            while (iter.next()) |kv| {
                for (0..ident + 1) |_| std.debug.print("  ", .{});
                std.debug.print("\"{s}\": ", .{kv.key_ptr.*});
                print_json_value(kv.value_ptr.*, ident + 1);
                std.debug.print(",\n", .{});
            }
            for (0..ident) |_| std.debug.print("  ", .{});
            std.debug.print("}}", .{});
        },
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const result = try json.parse("{ \"hi\": 2.5, \"obj\": { \"a\": 1, \"b\": false, }, \"yoo\": [1, \"hello!\", null], \"itWorks\": true }", &arena);

    print_json_value(result, 0);
    std.debug.print("\n", .{});
}
