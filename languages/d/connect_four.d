import std.array : appender;
import std.conv : to;
import std.stdio;
import std.string : strip;

enum ROWS = 6;
enum COLS = 7;
enum EMPTY = '.';
enum PLAYERS = "XO";

immutable string HEADER =
    "=== Connect Four ===\n" ~
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

string LABELS;
string BORDER;

char[COLS][ROWS] board;

string makeLabels() {
    string text = " ";
    foreach (column; 1 .. COLS + 1) {
        if (column > 1) {
            text ~= " ";
        }
        text ~= to!string(column);
    }
    return text;
}

string makeBorder() {
    string text = "+";
    foreach (_; 0 .. COLS * 2 - 1) {
        text ~= "-";
    }
    text ~= "+";
    return text;
}

void emit(string text) {
    write(text);
    stdout.flush();
}

string render() {
    auto buffer = appender!string();
    buffer.put(LABELS);
    buffer.put('\n');
    buffer.put(BORDER);
    buffer.put('\n');
    foreach (index; 0 .. ROWS) {
        int row = ROWS - 1 - index;
        buffer.put('|');
        foreach (column; 0 .. COLS) {
            if (column > 0) {
                buffer.put(' ');
            }
            buffer.put(board[row][column]);
        }
        buffer.put("|\n");
    }
    buffer.put(BORDER);
    buffer.put('\n');
    return buffer.data;
}

int lowestEmptyRow(int column) {
    foreach (row; 0 .. ROWS) {
        if (board[row][column] == EMPTY) {
            return row;
        }
    }
    return -1;
}

bool hasFour(char player) {
    foreach (row; 0 .. ROWS) {
        foreach (column; 0 .. COLS - 3) {
            if (board[row][column] == player
                && board[row][column + 1] == player
                && board[row][column + 2] == player
                && board[row][column + 3] == player) {
                return true;
            }
        }
    }
    foreach (row; 0 .. ROWS - 3) {
        foreach (column; 0 .. COLS) {
            if (board[row][column] == player
                && board[row + 1][column] == player
                && board[row + 2][column] == player
                && board[row + 3][column] == player) {
                return true;
            }
        }
    }
    foreach (row; 0 .. ROWS - 3) {
        foreach (column; 0 .. COLS - 3) {
            if (board[row][column] == player
                && board[row + 1][column + 1] == player
                && board[row + 2][column + 2] == player
                && board[row + 3][column + 3] == player) {
                return true;
            }
        }
    }
    foreach (row; 3 .. ROWS) {
        foreach (column; 0 .. COLS - 3) {
            if (board[row][column] == player
                && board[row - 1][column + 1] == player
                && board[row - 2][column + 2] == player
                && board[row - 3][column + 3] == player) {
                return true;
            }
        }
    }
    return false;
}

bool isWholeNumber(string token) {
    int start = 0;
    if (token.length > 0 && (token[0] == '+' || token[0] == '-')) {
        start = 1;
    }
    if (start >= token.length) {
        return false;
    }
    foreach (index; start .. token.length) {
        if (token[index] < '0' || token[index] > '9') {
            return false;
        }
    }
    return true;
}

// Parse with saturation so an absurd token cannot overflow a long.
long parseNumber(string token) {
    int index = 0;
    long sign = 1;
    if (token[0] == '-') {
        sign = -1;
        index = 1;
    } else if (token[0] == '+') {
        index = 1;
    }
    long value = 0;
    foreach (position; index .. token.length) {
        if (value > (long.max - 9) / 10) {
            return sign * long.max;
        }
        value = value * 10 + (token[position] - '0');
    }
    return sign * value;
}

int askColumn(char player) {
    while (true) {
        emit("Player " ~ player ~ ", choose a column (1-7): ");
        string line = readln();
        if (line is null) {
            emit("\nInput closed. Goodbye.\n");
            return -1;
        }
        string token = strip(line);
        string message;
        if (token.length == 0) {
            message = "Invalid input: no column entered.";
        } else if (!isWholeNumber(token)) {
            message = "Invalid input: \"" ~ token ~ "\" is not a whole number.";
        } else {
            long value = parseNumber(token);
            if (value < 1 || value > COLS) {
                message = "Invalid input: \"" ~ token ~ "\" is out of range (1-7).";
            } else if (lowestEmptyRow(cast(int) (value - 1)) < 0) {
                message = "Column " ~ to!string(value) ~ " is full.";
            } else {
                return cast(int) (value - 1);
            }
        }
        emit("\n" ~ message ~ "\n");
    }
}

void main() {
    LABELS = makeLabels();
    BORDER = makeBorder();
    foreach (row; 0 .. ROWS) {
        foreach (column; 0 .. COLS) {
            board[row][column] = EMPTY;
        }
    }

    emit(HEADER);
    emit("\n");
    emit(render());

    int moves = 0;
    int playerIndex = 0;
    while (true) {
        char player = PLAYERS[playerIndex];
        int column = askColumn(player);
        if (column < 0) {
            return;
        }
        board[lowestEmptyRow(column)][column] = player;
        moves++;
        emit("\n");
        emit(render());
        if (hasFour(player)) {
            emit("Player " ~ player ~ " wins!\n");
            return;
        }
        if (moves == ROWS * COLS) {
            emit("It's a tie!\n");
            return;
        }
        playerIndex = 1 - playerIndex;
    }
}
