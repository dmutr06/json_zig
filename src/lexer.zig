const std = @import("std");

pub const Token = union(enum) {
    lbrace,
    rbrace,
    lbracket,
    rbracket,
    colon,
    comma,
    string: []const u8,
    number: []const u8,
    true,
    false,
    null,
    eof,
    illegal,
};

pub const Lexer = struct {
    src: []const u8,
    pos: usize,
    ch: u8,

    pub fn init(src: []const u8) Lexer {
        return .{
            .src = src,
            .pos = 0,
            .ch = src[0],
        };
    }

    fn advance(self: *Lexer) void {
        if (self.pos + 1 == self.src.len) {
            self.ch = 0;
            self.pos += 1;
        } else if (self.pos < self.src.len) {
            self.ch = self.src[self.pos + 1];
            self.pos += 1;
        }
    }

    fn nextCh(self: Lexer) u8 {
        if (self.pos + 1 >= self.src.len) return 0;
        return self.src[self.pos + 1];
    }

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhitespace();

        const token: Token = switch (self.ch) {
            '{' => .lbrace,
            '}' => .rbrace,
            '[' => .lbracket,
            ']' => .rbracket,
            ':' => .colon,
            ',' => .comma,
            '"' => blk: {
                const string = self.readString();
                if (string) |str| {
                    break :blk .{ .string = str };
                }
                break :blk .illegal;
            },
            '0'...'9', '.' => blk: {
                const number = self.readNumber();
                if (number) |num| {
                    break :blk .{ .number = num };
                }
                break :blk .illegal;
            },
            'a'...'z', 'A'...'Z' => getKeyword(self.readKeyword()),
            0 => .eof,
            else => .illegal,
        };

        self.advance();
        return token;
    }

    fn skipWhitespace(self: *Lexer) void {
        while (std.ascii.isWhitespace(self.ch)) {
            self.advance();
        }
    }

    fn readString(self: *Lexer) ?[]const u8 {
        self.advance();
        const start = self.pos;

        while (self.ch != '"' and self.ch != 0) {
            if (self.ch == '\n') return null;
            self.advance();
        }

        if (self.ch == 0) return null;

        const end = self.pos;
        return self.src[start..end];
    }

    fn readNumber(self: *Lexer) ?[]const u8 {
        const start = self.pos;

        var dot_appeared = self.ch == '.';
        if (dot_appeared and !std.ascii.isDigit(self.nextCh())) return null;

        while (std.ascii.isDigit(self.nextCh()) or self.nextCh() == '.') {
            if (self.nextCh() == '.') {
                if (dot_appeared) return null;
                self.advance();
                if (!std.ascii.isDigit(self.nextCh())) return null;
                dot_appeared = true;
            } else {
                self.advance();
            }
        }

        const end = self.pos + 1;

        return self.src[start..end];
    }

    fn readKeyword(self: *Lexer) []const u8 {
        const start = self.pos;

        while (std.ascii.isAlphabetic(self.nextCh())) {
            self.advance();
        }

        const end = self.pos + 1;

        return self.src[start..end];
    }

    fn getKeyword(keyword: []const u8) Token {
        const map = std.StaticStringMap(Token).initComptime(.{
            .{ "null", .null },
            .{ "true", .true },
            .{ "false", .false },
        });

        return map.get(keyword) orelse .illegal;
    }
};
