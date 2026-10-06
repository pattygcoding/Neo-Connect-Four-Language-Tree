class ConnectFour {
    static inline var ROWS:Int = 6;
    static inline var COLS:Int = 7;
    static inline var EMPTY:String = ".";
    static var PLAYERS:Array<String> = ["X", "O"];

    static var HEADER:String =
        "=== Connect Four ===\n" +
        "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

    static var LABELS:String = makeLabels();
    static var BORDER:String = makeBorder();

    static var board:Array<Array<String>>;

    static function emit(text:String):Void {
        Sys.stdout().writeString(text);
        Sys.stdout().flush();
    }

    // readLine throws haxe.io.Eof at end of input instead of returning null.
    static function readLine():Null<String> {
        try {
            return Sys.stdin().readLine();
        } catch (error:haxe.io.Eof) {
            return null;
        }
    }

    static function makeLabels():String {
        var buffer = new StringBuf();
        buffer.add(" ");
        for (column in 1...(COLS + 1)) {
            if (column > 1) {
                buffer.add(" ");
            }
            buffer.add(Std.string(column));
        }
        return buffer.toString();
    }

    static function makeBorder():String {
        var buffer = new StringBuf();
        buffer.add("+");
        for (_ in 0...(COLS * 2 - 1)) {
            buffer.add("-");
        }
        buffer.add("+");
        return buffer.toString();
    }

    static function render():String {
        var buffer = new StringBuf();
        buffer.add(LABELS);
        buffer.add("\n");
        buffer.add(BORDER);
        buffer.add("\n");
        var row = ROWS - 1;
        while (row >= 0) {
            buffer.add("|");
            for (column in 0...COLS) {
                if (column > 0) {
                    buffer.add(" ");
                }
                buffer.add(board[row][column]);
            }
            buffer.add("|\n");
            row--;
        }
        buffer.add(BORDER);
        buffer.add("\n");
        return buffer.toString();
    }

    static function lowestEmptyRow(column:Int):Int {
        for (row in 0...ROWS) {
            if (board[row][column] == EMPTY) {
                return row;
            }
        }
        return -1;
    }

    static function hasFour(player:String):Bool {
        for (row in 0...ROWS) {
            for (column in 0...(COLS - 3)) {
                if (board[row][column] == player && board[row][column + 1] == player
                    && board[row][column + 2] == player && board[row][column + 3] == player) {
                    return true;
                }
            }
        }
        for (row in 0...(ROWS - 3)) {
            for (column in 0...COLS) {
                if (board[row][column] == player && board[row + 1][column] == player
                    && board[row + 2][column] == player && board[row + 3][column] == player) {
                    return true;
                }
            }
        }
        for (row in 0...(ROWS - 3)) {
            for (column in 0...(COLS - 3)) {
                if (board[row][column] == player && board[row + 1][column + 1] == player
                    && board[row + 2][column + 2] == player && board[row + 3][column + 3] == player) {
                    return true;
                }
            }
        }
        for (row in 3...ROWS) {
            for (column in 0...(COLS - 3)) {
                if (board[row][column] == player && board[row - 1][column + 1] == player
                    && board[row - 2][column + 2] == player && board[row - 3][column + 3] == player) {
                    return true;
                }
            }
        }
        return false;
    }

    static function isWhitespace(code:Int):Bool {
        return code == 32 || (code >= 9 && code <= 13);
    }

    static function trim(text:String):String {
        var start = 0;
        var end = text.length;
        while (start < end && isWhitespace(text.charCodeAt(start))) {
            start++;
        }
        while (end > start && isWhitespace(text.charCodeAt(end - 1))) {
            end--;
        }
        return text.substr(start, end - start);
    }

    static function isWholeNumber(token:String):Bool {
        var start = (token.length > 0 && (token.charCodeAt(0) == 43 || token.charCodeAt(0) == 45)) ? 1 : 0;
        if (start >= token.length) {
            return false;
        }
        var index = start;
        while (index < token.length) {
            var code = token.charCodeAt(index);
            if (code < 48 || code > 57) {
                return false;
            }
            index++;
        }
        return true;
    }

    // Parse with saturation so an absurd token cannot overflow an Int.
    static function parseNumber(token:String):Int {
        var sign = 1;
        var index = 0;
        if (token.charCodeAt(0) == 45) {
            sign = -1;
            index = 1;
        } else if (token.charCodeAt(0) == 43) {
            index = 1;
        }
        var value = 0;
        while (index < token.length) {
            if (value > 100000000) {
                return sign * 2147483647;
            }
            value = value * 10 + (token.charCodeAt(index) - 48);
            index++;
        }
        return sign * value;
    }

    static function askColumn(player:String):Int {
        while (true) {
            emit("Player " + player + ", choose a column (1-7): ");
            var line = readLine();
            if (line == null) {
                emit("\nInput closed. Goodbye.\n");
                return -1;
            }
            var token = trim(line);
            var message:String;
            if (token.length == 0) {
                message = "Invalid input: no column entered.";
            } else if (!isWholeNumber(token)) {
                message = "Invalid input: \"" + token + "\" is not a whole number.";
            } else {
                var value = parseNumber(token);
                if (value < 1 || value > COLS) {
                    message = "Invalid input: \"" + token + "\" is out of range (1-7).";
                } else if (lowestEmptyRow(value - 1) < 0) {
                    message = "Column " + value + " is full.";
                } else {
                    return value - 1;
                }
            }
            emit("\n" + message + "\n");
        }
    }

    static function main():Void {
        board = [];
        for (row in 0...ROWS) {
            var cells = [];
            for (column in 0...COLS) {
                cells.push(EMPTY);
            }
            board.push(cells);
        }

        emit(HEADER);
        emit("\n");
        emit(render());

        var moves = 0;
        var playerIndex = 0;
        while (true) {
            var player = PLAYERS[playerIndex];
            var column = askColumn(player);
            if (column < 0) {
                return;
            }
            board[lowestEmptyRow(column)][column] = player;
            moves++;
            emit("\n");
            emit(render());
            if (hasFour(player)) {
                emit("Player " + player + " wins!\n");
                return;
            }
            if (moves == ROWS * COLS) {
                emit("It's a tie!\n");
                return;
            }
            playerIndex = 1 - playerIndex;
        }
    }
}

