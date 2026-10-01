ROWS = 6
COLUMNS = 7
EMPTY = "."
PLAYERS = ("X", "O")

DIRECTIONS = ((0, 1), (1, 0), (1, 1), (1, -1))


class Board:
    """A 6x7 Connect Four position; row 0 is the bottom row."""

    def __init__(self, cells=None, moves=0):
        self.cells = (
            [row[:] for row in cells]
            if cells is not None
            else [[EMPTY for _ in range(COLUMNS)] for _ in range(ROWS)]
        )
        self.moves = moves

    @property
    def current_player(self):
        return PLAYERS[self.moves % len(PLAYERS)]

    def other_player(self, player):
        return PLAYERS[0] if player == PLAYERS[1] else PLAYERS[1]

    def lowest_empty_row(self, column):
        for row in range(ROWS):
            if self.cells[row][column] == EMPTY:
                return row
        return -1

    def is_full(self, column):
        return self.lowest_empty_row(column) < 0

    def available_columns(self):
        return [column for column in range(COLUMNS) if not self.is_full(column)]

    def drop(self, column, player):
        """Place `player`'s disc in `column`; return the row, or -1 when full."""
        row = self.lowest_empty_row(column)
        if row < 0:
            return -1
        self.cells[row][column] = player
        self.moves += 1
        return row

    def undo(self, column, row):
        """Remove the disc a matching `drop` added, so the search can unmake it."""
        self.cells[row][column] = EMPTY
        self.moves -= 1

    def matches(self, row, column, player):
        return 0 <= row < ROWS and 0 <= column < COLUMNS and self.cells[row][column] == player

    def won_from(self, row, column, player):
        """True when the disc at (row, column) completes a line for `player`."""
        for row_step, column_step in DIRECTIONS:
            count = 1
            count += self._count(row, column, row_step, column_step, player)
            count += self._count(row, column, -row_step, -column_step, player)
            if count >= 4:
                return True
        return False

    def _count(self, row, column, row_step, column_step, player):
        total = 0
        row += row_step
        column += column_step
        while self.matches(row, column, player):
            total += 1
            row += row_step
            column += column_step
        return total

    def winner(self):
        for player in PLAYERS:
            if any(
                self.cells[row][column] == player and self.won_from(row, column, player)
                for row in range(ROWS)
                for column in range(COLUMNS)
            ):
                return player
        return None

    def is_over(self):
        return self.winner() is not None or self.moves == ROWS * COLUMNS
