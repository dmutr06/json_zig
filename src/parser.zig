const Lexer = @import("./lexer.zig").Lexer;
const Token = @import("./lexer.zig").Token;

const JsonValue = @import("./root.zig").JsonValue;

const std = @import("std");

pub fn parse(src: []const u8, arena: *std.heap.ArenaAllocator) !JsonValue {
    var allocator = arena.allocator();
    var lexer = Lexer.init(src);

    const val: JsonValue = switch (lexer.nextToken()) {
        .string => |str| .{ .string = try allocator.dupe(u8, str) },
        .number => |num| .{ .number = try std.fmt.parseFloat(f64, num) },
        .true => .{ .boolean = true },
        .false => .{ .boolean = false },
        .null, .eof => .null,
        .lbracket => try parseArray(&lexer, allocator),
        .lbrace => try parseObject(&lexer, allocator),
        else => return error.BadJson,
    };

    if (lexer.nextToken() == .eof) return val;

    return error.BadJson;
}

fn parseArray(lexer: *Lexer, allocator: std.mem.Allocator) anyerror!JsonValue {
    var token = lexer.nextToken();
    var array = std.ArrayList(JsonValue).init(allocator);

    while (token != .rbracket) {
        try array.append(try tokenToValue(lexer, token, allocator));

        token = lexer.nextToken();
        if (token != .comma and token != .rbracket) return error.BadJson;
        if (token == .rbracket) break;
        token = lexer.nextToken();
    }

    return .{ .array = array };
}

fn parseObject(lexer: *Lexer, allocator: std.mem.Allocator) anyerror!JsonValue {
    var token = lexer.nextToken();
    var object = std.StringHashMap(JsonValue).init(allocator);

    while (token != .rbrace) {
        if (token != .string) return error.BadJson;
        if (lexer.nextToken() != .colon) return error.BadJson;

        const key = token.string;
        token = lexer.nextToken();

        try object.put(key, try tokenToValue(lexer, token, allocator));

        token = lexer.nextToken();
        if (token != .comma and token != .rbrace) return error.BadJson;
        if (token == .rbrace) break;
        token = lexer.nextToken();
    }

    return .{ .object = object };
}

fn tokenToValue(lexer: *Lexer, token: Token, allocator: std.mem.Allocator) anyerror!JsonValue {
    return switch (token) {
        .string => |str| .{ .string = try allocator.dupe(u8, str) },
        .number => |num| .{ .number = try std.fmt.parseFloat(f64, num) },
        .true => .{ .boolean = true },
        .false => .{ .boolean = false },
        .null => .null,
        .lbracket => try parseArray(lexer, allocator),
        .lbrace => try parseObject(lexer, allocator),
        else => return error.BadJson,
    };
}
