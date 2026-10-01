ROWS = 6
COLUMNS = 7
EMPTY = "."
PLAYERS = ("X", "O")

DIRECTIONS = ((0, 1), (1, 0), (1, 1), (1, -1))


class Board:
    """A 6x7 Connect Four position; row 0 is the bottom row."""

    def __init__(self):
        self.cells = [[EMPTY for _ in range(COLUMNS)] for _ in range(ROWS)]
        self.moves = 0

    @property
    def current_player(self):
        return PLAYERS[self.moves % len(PLAYERS)]

    def lowest_empty_row(self, column):
        for row in range(ROWS):
            if self.cells[row][column] == EMPTY:
                return row
        return -1

    def column_height(self, column):
        row = self.lowest_empty_row(column)
        return ROWS if row < 0 else row

    def is_full(self, column):
        return self.lowest_empty_row(column) < 0

    def drop(self, column):
        """Drop the current player's disc in `column`; False when it is full."""
        row = self.lowest_empty_row(column)
        if row < 0:
            return False
        self.cells[row][column] = self.current_player
        self.moves += 1
        return True

    def matches(self, row, column, player):
        return 0 <= row < ROWS and 0 <= column < COLUMNS and self.cells[row][column] == player

    def winner(self):
        for player in PLAYERS:
            for row in range(ROWS):
                for column in range(COLUMNS):
                    if self.cells[row][column] != player:
                        continue
                    for row_step, column_step in DIRECTIONS:
                        if all(
                            self.matches(row + index * row_step, column + index * column_step, player)
                            for index in range(4)
                        ):
                            return player
        return None

    def is_over(self):
        return self.winner() is not None or self.moves == ROWS * COLUMNS
