const std = @import("std");

pub const lexer = @import("./lexer.zig");

pub const parse = @import("./parser.zig").parse;

pub const JsonValue = union(enum) {
    null,
    boolean: bool,
    number: f64,
    string: []const u8,
    array: std.ArrayList(JsonValue),
    object: std.StringHashMap(JsonValue),
};
