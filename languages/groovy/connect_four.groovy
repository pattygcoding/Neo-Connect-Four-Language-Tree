import groovy.transform.Field

@Field final int ROWS = 6
@Field final int COLS = 7
@Field final String EMPTY = "."
@Field final List<String> PLAYERS = ["X", "O"]
@Field final String BORDER = "+" + ("-" * (COLS * 2 - 1)) + "+"
@Field final String LABELS = " " + (1..COLS).join(" ")
@Field final String HEADER = "=== Connect Four ===\n" +
        "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"
@Field final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in))

List<List<String>> newBoard() {
    return (1..ROWS).collect { (1..COLS).collect { EMPTY } }
}

String render(List<List<String>> board) {
    List<String> lines = [LABELS, BORDER]
    for (int row = ROWS - 1; row >= 0; row--) {
        lines << "|" + board[row].join(" ") + "|"
    }
    lines << BORDER
    return lines.join("\n")
}

int lowestEmptyRow(List<List<String>> board, int column) {
    for (int row = 0; row < ROWS; row++) {
        if (board[row][column] == EMPTY) {
            return row
        }
    }
    return -1
}

boolean hasFour(List<List<String>> board, String player) {
    for (int row = 0; row < ROWS; row++) {
        for (int col = 0; col <= COLS - 4; col++) {
            if ((0..3).every { board[row][col + it] == player }) {
                return true
            }
        }
    }
    for (int row = 0; row <= ROWS - 4; row++) {
        for (int col = 0; col < COLS; col++) {
            if ((0..3).every { board[row + it][col] == player }) {
                return true
            }
        }
    }
    for (int row = 0; row <= ROWS - 4; row++) {
        for (int col = 0; col <= COLS - 4; col++) {
            if ((0..3).every { board[row + it][col + it] == player }) {
                return true
            }
        }
    }
    for (int row = 3; row < ROWS; row++) {
        for (int col = 0; col <= COLS - 4; col++) {
            if ((0..3).every { board[row - it][col + it] == player }) {
                return true
            }
        }
    }
    return false
}

boolean isWholeNumber(String token) {
    String body = (token.startsWith("+") || token.startsWith("-")) ? token.substring(1) : token
    return !body.isEmpty() && body.matches("[0-9]+")
}

long parseValue(String token) {
    boolean negative = token.startsWith("-")
    String body = (token.startsWith("+") || token.startsWith("-")) ? token.substring(1) : token
    long value = 0L
    for (int index = 0; index < body.length(); index++) {
        int digit = body.charAt(index) - (int) '0'
        if (value > (Long.MAX_VALUE - digit) / 10) {
            value = Long.MAX_VALUE
            break
        }
        value = value * 10 + digit
    }
    return negative ? -value : value
}

void write(String text) {
    System.out.print(text)
}

Integer askColumn(List<List<String>> board, String player) {
    while (true) {
        write("Player " + player + ", choose a column (1-7): ")
        System.out.flush()
        String line = reader.readLine()
        if (line == null) {
            write("\nInput closed. Goodbye.\n")
            System.out.flush()
            return null
        }
        String token = line.trim()
        String message
        if (token.isEmpty()) {
            message = "Invalid input: no column entered."
        } else if (!isWholeNumber(token)) {
            message = 'Invalid input: "' + token + '" is not a whole number.'
        } else {
            long value = parseValue(token)
            if (value < 1 || value > COLS) {
                message = 'Invalid input: "' + token + '" is out of range (1-7).'
            } else if (lowestEmptyRow(board, ((int) value) - 1) == -1) {
                message = "Column " + value + " is full."
            } else {
                return ((int) value) - 1
            }
        }
        write("\n" + message + "\n")
        System.out.flush()
    }
}

List<List<String>> board = newBoard()
write(HEADER + "\n" + render(board) + "\n")
System.out.flush()
int moves = 0
int playerIndex = 0
while (true) {
    String player = PLAYERS[playerIndex]
    Integer column = askColumn(board, player)
    if (column == null) {
        return
    }
    board[lowestEmptyRow(board, column)][column] = player
    moves++
    write("\n" + render(board) + "\n")
    System.out.flush()
    if (hasFour(board, player)) {
        write("Player " + player + " wins!\n")
        System.out.flush()
        return
    }
    if (moves == ROWS * COLS) {
        write("It's a tie!\n")
        System.out.flush()
        return
    }
    playerIndex = 1 - playerIndex
}
