const std = @import("std");

const rows = 6;
const cols = 7;
const span = cols - 3;
const vspan = rows - 3;
const empty = '.';
const players = "XO";

const header =
    "=== Connect Four ===\n" ++
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

var board: [rows * cols]u8 = [_]u8{empty} ** (rows * cols);
var line_buf: [4096]u8 = undefined;
var byte_buf: [1]u8 = undefined;
var out_buf: [4096]u8 = undefined;
var io: std.Io = undefined;
var out: std.Io.File = undefined;
var in: std.Io.File = undefined;

const Buf = struct {
    data: []u8,
    len: usize = 0,

    fn put(self: *Buf, ch: u8) void {
        if (self.len < self.data.len) {
            self.data[self.len] = ch;
            self.len += 1;
        }
    }

    fn putAll(self: *Buf, bytes: []const u8) void {
        for (bytes) |ch| {
            self.put(ch);
        }
    }

    fn putNumber(self: *Buf, value: u32) void {
        var digits: [10]u8 = undefined;
        var count: usize = 0;
        var rest = value;
        if (rest == 0) {
            self.put('0');
            return;
        }
        while (rest > 0) {
            digits[count] = '0' + @as(u8, @intCast(rest % 10));
            count += 1;
            rest /= 10;
        }
        while (count > 0) {
            count -= 1;
            self.put(digits[count]);
        }
    }

    fn slice(self: *const Buf) []const u8 {
        return self.data[0..self.len];
    }
};

fn emit(bytes: []const u8) !void {
    try out.writeStreamingAll(io, bytes);
}

fn cell(row: usize, col: usize) u8 {
    return board[row * cols + col];
}

fn lowestEmptyRow(col: usize) isize {
    for (0..rows) |row| {
        if (cell(row, col) == empty) return @intCast(row);
    }
    return -1;
}

fn hasFour(player: u8) bool {
    for (0..rows) |row| {
        for (0..span) |col| {
            if (cell(row, col) == player and cell(row, col + 1) == player and
                cell(row, col + 2) == player and cell(row, col + 3) == player)
            {
                return true;
            }
        }
    }
    for (0..vspan) |row| {
        for (0..cols) |col| {
            if (cell(row, col) == player and cell(row + 1, col) == player and
                cell(row + 2, col) == player and cell(row + 3, col) == player)
            {
                return true;
            }
        }
    }
    for (0..vspan) |row| {
        for (0..span) |col| {
            if (cell(row, col) == player and cell(row + 1, col + 1) == player and
                cell(row + 2, col + 2) == player and cell(row + 3, col + 3) == player)
            {
                return true;
            }
        }
    }
    for (vspan..rows) |row| {
        for (0..span) |col| {
            if (cell(row, col) == player and cell(row - 1, col + 1) == player and
                cell(row - 2, col + 2) == player and cell(row - 3, col + 3) == player)
            {
                return true;
            }
        }
    }
    return false;
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or (ch >= 9 and ch <= 13);
}

fn trimWhitespace(line: []u8) []u8 {
    var start: usize = 0;
    while (start < line.len and isSpace(line[start])) start += 1;
    var end: usize = line.len;
    while (end > start and isSpace(line[end - 1])) end -= 1;
    return line[start..end];
}

fn isWholeNumber(token: []const u8) bool {
    var rest = token;
    if (rest.len > 0 and (rest[0] == '+' or rest[0] == '-')) rest = rest[1..];
    if (rest.len == 0) return false;
    for (rest) |ch| {
        if (ch < '0' or ch > '9') return false;
    }
    return true;
}

const ColumnResult = union(enum) {
    ok: u8,
    full: u32,
    out_of_range,
};

fn classifyColumn(token: []const u8) ColumnResult {
    var rest = token;
    if (rest[0] == '-') return .out_of_range;
    if (rest[0] == '+') rest = rest[1..];
    var value: u32 = 0;
    for (rest) |ch| {
        value = value * 10 + (ch - '0');
        if (value > 1000) return .out_of_range;
    }
    if (value < 1 or value > cols) return .out_of_range;
    const col: u8 = @intCast(value - 1);
    if (lowestEmptyRow(col) < 0) return .{ .full = value };
    return .{ .ok = col };
}

fn readLine() !?[]u8 {
    var len: usize = 0;
    var got = false;
    while (true) {
        const n = in.readStreaming(io, &.{&byte_buf}) catch |err| switch (err) {
            error.EndOfStream => {
                if (!got) return null;
                break;
            },
            else => return err,
        };
        if (n == 0) continue;
        got = true;
        const ch = byte_buf[0];
        if (ch == '\n') break;
        if (len < line_buf.len - 1) {
            line_buf[len] = ch;
            len += 1;
        }
    }
    line_buf[len] = 0;
    return line_buf[0..len];
}

fn printBorder() !void {
    var b = Buf{ .data = &out_buf };
    b.put('+');
    for (0..cols * 2 - 1) |_| b.put('-');
    b.putAll("+\n");
    try emit(b.slice());
}

fn printBoard() !void {
    var b = Buf{ .data = &out_buf };
    b.put(' ');
    for (1..cols + 1) |col| {
        if (col > 1) b.put(' ');
        b.put('0' + @as(u8, @intCast(col)));
    }
    b.put('\n');
    try emit(b.slice());

    try printBorder();

    var row: usize = rows;
    while (row > 0) {
        row -= 1;
        var line = Buf{ .data = &out_buf };
        line.put('|');
        for (0..cols) |col| {
            if (col > 0) line.put(' ');
            line.put(cell(row, col));
        }
        line.putAll("|\n");
        try emit(line.slice());
    }

    try printBorder();
}

fn askColumn(player: u8) !?u8 {
    while (true) {
        var prompt = Buf{ .data = &out_buf };
        prompt.putAll("Player ");
        prompt.put(player);
        prompt.putAll(", choose a column (1-7): ");
        try emit(prompt.slice());

        const line = (try readLine()) orelse {
            try emit("\nInput closed. Goodbye.\n");
            return null;
        };
        const token = trimWhitespace(line);
        if (token.len == 0) {
            try emit("\nInvalid input: no column entered.\n");
        } else if (!isWholeNumber(token)) {
            var b = Buf{ .data = &out_buf };
            b.putAll("\nInvalid input: \"");
            b.putAll(token);
            b.putAll("\" is not a whole number.\n");
            try emit(b.slice());
        } else switch (classifyColumn(token)) {
            .ok => |column| return column,
            .full => |value| {
                var b = Buf{ .data = &out_buf };
                b.putAll("\nColumn ");
                b.putNumber(value);
                b.putAll(" is full.\n");
                try emit(b.slice());
            },
            .out_of_range => {
                var b = Buf{ .data = &out_buf };
                b.putAll("\nInvalid input: \"");
                b.putAll(token);
                b.putAll("\" is out of range (1-7).\n");
                try emit(b.slice());
            },
        }
    }
}

pub fn main() !void {
    io = std.Io.Threaded.global_single_threaded.io();
    out = std.Io.File.stdout();
    in = std.Io.File.stdin();

    try emit(header);
    try emit("\n");
    try printBoard();

    var moves: u32 = 0;
    var player_index: usize = 0;
    while (true) {
        const player = players[player_index];
        const column = (try askColumn(player)) orelse return;
        const row: usize = @intCast(lowestEmptyRow(column));
        board[row * cols + column] = player;
        moves += 1;
        try emit("\n");
        try printBoard();
        if (hasFour(player)) {
            var b = Buf{ .data = &out_buf };
            b.putAll("Player ");
            b.put(player);
            b.putAll(" wins!\n");
            try emit(b.slice());
            return;
        }
        if (moves == rows * cols) {
            try emit("It's a tie!\n");
            return;
        }
        player_index = 1 - player_index;
    }
}
