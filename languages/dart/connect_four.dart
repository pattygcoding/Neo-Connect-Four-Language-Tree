import 'dart:io';

const int rows = 6;
const int cols = 7;
const String empty = '.';
const String players = 'XO';
const int maxInt = 9223372036854775807;
const String header =
    '=== Connect Four ===\n'
    'Get four of your pieces in a row to win. Columns are numbered 1-7.\n';

final String border = '+' + '-' * (cols * 2 - 1) + '+';

List<List<String>> newBoard() => List<List<String>>.generate(
    rows, (int row) => List<String>.filled(cols, empty));

int lowestEmptyRow(List<List<String>> board, int column) {
    for (int row = 0; row < rows; row++) {
        if (board[row][column] == empty) {
            return row;
        }
    }
    return -1;
}

bool hasFour(List<List<String>> board, String player) {
    bool at(int row, int column) {
        return row >= 0 &&
            row < rows &&
            column >= 0 &&
            column < cols &&
            board[row][column] == player;
    }

    bool run(int row, int column, int rowStep, int columnStep) {
        for (int step = 0; step < 4; step++) {
            if (!at(row + step * rowStep, column + step * columnStep)) {
                return false;
            }
        }
        return true;
    }

    for (int row = 0; row < rows; row++) {
        for (int column = 0; column < cols; column++) {
            if (run(row, column, 0, 1) ||
                run(row, column, 1, 0) ||
                run(row, column, 1, 1) ||
                run(row, column, 1, -1)) {
                return true;
            }
        }
    }
    return false;
}

String render(List<List<String>> board) {
    final StringBuffer output = StringBuffer();
    final List<String> labels =
        List<String>.generate(cols, (int index) => '${index + 1}');
    output.writeln(' ${labels.join(' ')}');
    output.writeln(border);
    for (int row = rows - 1; row >= 0; row--) {
        output.writeln('|${board[row].join(' ')}|');
    }
    output.writeln(border);
    return output.toString();
}

bool isWholeNumber(String token) {
    final String body =
        token.startsWith('+') || token.startsWith('-') ? token.substring(1) : token;
    if (body.isEmpty) {
        return false;
    }
    for (final int code in body.codeUnits) {
        if (code < 0x30 || code > 0x39) {
            return false;
        }
    }
    return true;
}

int parseValue(String token) {
    bool negative = false;
    String body = token;
    if (body.startsWith('+') || body.startsWith('-')) {
        negative = body.startsWith('-');
        body = body.substring(1);
    }
    int value = 0;
    for (final int code in body.codeUnits) {
        final int digit = code - 0x30;
        if (value > (maxInt - digit) ~/ 10) {
            value = maxInt;
            break;
        }
        value = value * 10 + digit;
    }
    return negative ? -value : value;
}

int askColumn(List<List<String>> board, String player) {
    while (true) {
        stdout.write('Player $player, choose a column (1-7): ');
        final String? line = stdin.readLineSync();
        if (line == null) {
            stdout.write('\nInput closed. Goodbye.\n');
            return -1;
        }
        final String token = line.trim();
        if (token.isEmpty) {
            stdout.write('\nInvalid input: no column entered.\n');
            continue;
        }
        if (!isWholeNumber(token)) {
            stdout.write('\nInvalid input: "$token" is not a whole number.\n');
            continue;
        }
        final int value = parseValue(token);
        if (value < 1 || value > cols) {
            stdout.write('\nInvalid input: "$token" is out of range (1-7).\n');
            continue;
        }
        if (lowestEmptyRow(board, value - 1) < 0) {
            stdout.write('\nColumn $value is full.\n');
            continue;
        }
        return value - 1;
    }
}

void main() {
    final List<List<String>> board = newBoard();
    stdout.write('$header\n');
    stdout.write(render(board));
    int playerIndex = 0;
    int moves = 0;
    while (true) {
        final String player = players[playerIndex];
        final int column = askColumn(board, player);
        if (column < 0) {
            break;
        }
        final int row = lowestEmptyRow(board, column);
        board[row][column] = player;
        moves++;
        stdout.write('\n');
        stdout.write(render(board));
        if (hasFour(board, player)) {
            stdout.writeln('Player $player wins!');
            break;
        }
        if (moves == rows * cols) {
            stdout.writeln("It's a tie!");
            break;
        }
        playerIndex = 1 - playerIndex;
    }
}
