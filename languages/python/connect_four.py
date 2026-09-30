import sys

ROWS = 6
COLS = 7
EMPTY = "."
PLAYERS = ("X", "O")

BORDER = "+" + "-" * (COLS * 2 - 1) + "+"
LABELS = " " + " ".join(str(c + 1) for c in range(COLS))

HEADER = (
    "=== Connect Four ===\n"
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"
)


def new_board():
    """Return an empty board; board[0] is the bottom row."""
    return [[EMPTY for _ in range(COLS)] for _ in range(ROWS)]


def render(board):
    """Render the board as a single string (no trailing newline)."""
    lines = [LABELS, BORDER]
    for row in range(ROWS - 1, -1, -1):
        lines.append("|" + " ".join(board[row]) + "|")
    lines.append(BORDER)
    return "\n".join(lines)


def lowest_empty_row(board, column):
    """Return the lowest empty row index in `column`, or -1 if full."""
    for row in range(ROWS):
        if board[row][column] == EMPTY:
            return row
    return -1


def has_four(board, player):
    """Return True if `player` has four in a row anywhere on the board."""
    # Horizontal.
    for row in range(ROWS):
        for col in range(COLS - 3):
            if all(board[row][col + k] == player for k in range(4)):
                return True
    # Vertical.
    for row in range(ROWS - 3):
        for col in range(COLS):
            if all(board[row + k][col] == player for k in range(4)):
                return True
    # Diagonal (up-right).
    for row in range(ROWS - 3):
        for col in range(COLS - 3):
            if all(board[row + k][col + k] == player for k in range(4)):
                return True
    # Diagonal (down-right).
    for row in range(3, ROWS):
        for col in range(COLS - 3):
            if all(board[row - k][col + k] == player for k in range(4)):
                return True
    return False


def is_whole_number(token):
    """True only for an optional sign followed by ASCII digits."""
    body = token[1:] if token[:1] in "+-" else token
    return body.isdigit() and body.isascii()


def write(text):
    sys.stdout.write(text)


def prompt(player):
    return "Player %s, choose a column (1-7): " % player


def ask_column(board, player):
    """Read a valid column from stdin.

    Returns the zero-based column index, or None when stdin is closed.
    Prints a warning and re-prompts on invalid input.
    """
    while True:
        write(prompt(player))
        sys.stdout.flush()
        line = sys.stdin.readline()
        if line == "":
            write("\nInput closed. Goodbye.\n")
            return None
        token = line.strip()
        if token == "":
            message = "Invalid input: no column entered."
        elif not is_whole_number(token):
            message = 'Invalid input: "%s" is not a whole number.' % token
        else:
            value = int(token)
            if value < 1 or value > COLS:
                message = 'Invalid input: "%s" is out of range (1-7).' % token
            elif lowest_empty_row(board, value - 1) == -1:
                message = "Column %d is full." % value
            else:
                return value - 1
        write("\n" + message + "\n")
        sys.stdout.flush()


def main():
    board = new_board()
    write(HEADER + "\n" + render(board) + "\n")
    moves = 0
    player_index = 0
    while True:
        player = PLAYERS[player_index]
        column = ask_column(board, player)
        if column is None:
            return 0
        board[lowest_empty_row(board, column)][column] = player
        moves += 1
        write("\n" + render(board) + "\n")
        if has_four(board, player):
            write("Player %s wins!\n" % player)
            return 0
        if moves == ROWS * COLS:
            write("It's a tie!\n")
            return 0
        player_index = 1 - player_index


if __name__ == "__main__":
    sys.exit(main())
