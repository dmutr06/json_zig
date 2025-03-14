const Lexer = @import("./lexer.zig").Lexer;

const JsonValue = @import("./root.zig").JsonValue;

const std = @import("std");

pub fn parse(src: []const u8) !JsonValue {
    var lexer = Lexer.init(src);

    const val: JsonValue = switch (lexer.nextToken()) {
        .string => |str| .{ .string = str },
        .number => |num| .{ .number = try std.fmt.parseFloat(f64, num) },
        .true => .{ .boolean = true },
        .false => .{ .boolean = false },
        .null, .eof => .null,
        .lbracket => try parseArray(&lexer),
        .lbrace => try parseObject(&lexer),
        else => return error.BadJson,
    };

    if (lexer.nextToken() == .eof) return val;

    return error.BadJson;
}

fn parseArray(lexer: *Lexer) anyerror!JsonValue {
    var token = lexer.nextToken();
    var array = std.ArrayList(JsonValue).init(std.heap.page_allocator);

    while (token != .rbracket) {
        switch (token) {
            .null => try array.append(.null),
            .string => |str| try array.append(.{ .string = str }),
            .true => try array.append(.{ .boolean = true }),
            .false => try array.append(.{ .boolean = false }),
            .number => |num| try array.append(.{ .number = try std.fmt.parseFloat(f64, num) }),
            .lbracket => try array.append(try parseArray(lexer)),
            .lbrace => try array.append(try parseObject(lexer)),
            .illegal, .eof, .rbrace, .colon, .comma, .rbracket => return error.BadJson,
        }

        token = lexer.nextToken();
        if (token != .comma and token != .rbracket) return error.BadJson;
        if (token == .rbracket) break;
        token = lexer.nextToken();
    }

    return .{ .array = array };
}

fn parseObject(lexer: *Lexer) anyerror!JsonValue {
    var token = lexer.nextToken();
    var object = std.StringHashMap(JsonValue).init(std.heap.page_allocator);

    while (token != .rbrace) {
        if (token != .string) return error.BadJson;
        if (lexer.nextToken() != .colon) return error.BadJson;

        const key = token.string;
        token = lexer.nextToken();

        switch (token) {
            .null => try object.put(key, .null),
            .string => |str| try object.put(key, .{ .string = str }),
            .true => try object.put(key, .{ .boolean = true }),
            .false => try object.put(key, .{ .boolean = false }),
            .number => |num| try object.put(key, .{ .number = try std.fmt.parseFloat(f64, num) }),
            .lbracket => try object.put(key, try parseArray(lexer)),
            .lbrace => try object.put(key, try parseObject(lexer)),
            .illegal, .eof, .rbrace, .colon, .comma, .rbracket => return error.BadJson,
        }

        token = lexer.nextToken();
        if (token != .comma and token != .rbrace) return error.BadJson;
        if (token == .rbrace) break;
        token = lexer.nextToken();
    }

    return .{ .object = object };
}
