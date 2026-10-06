ROWS = 6
COLUMNS = 7
EMPTY = "."
PLAYERS = ("X", "O")
DIRECTIONS = ((0, 1), (1, 0), (1, 1), (1, -1))


class ConnectFourBoard:
    def __init__(self):
        self.cells = [[EMPTY] * COLUMNS for _ in range(ROWS)]
        self.moves = 0

    @property
    def current_player(self):
        return PLAYERS[self.moves % len(PLAYERS)]

    @property
    def winner(self):
        for player in PLAYERS:
            if self.has_line(player):
                return player
        return None

    @property
    def is_over(self):
        return self.winner is not None or self.moves == ROWS * COLUMNS

    def legal_columns(self):
        return [column for column in range(COLUMNS) if not self.is_full(column)]

    def is_full(self, column):
        return self.lowest_empty_row(column) is None

    def drop(self, column):
        row = self.lowest_empty_row(column)
        if row is None:
            return False
        self.cells[row][column] = self.current_player
        self.moves += 1
        return True

    def lowest_empty_row(self, column):
        for row in range(ROWS):
            if self.cells[row][column] == EMPTY:
                return row
        return None

    def render(self):
        lines = [" ".join(row) for row in reversed(self.cells)]
        lines.append(" ".join(str(column + 1) for column in range(COLUMNS)))
        return "\n".join(lines)

    def has_line(self, player):
        for row in range(ROWS):
            for column in range(COLUMNS):
                if self.cells[row][column] != player:
                    continue
                for row_step, column_step in DIRECTIONS:
                    if all(
                        self.matches(row + row_step * step, column + column_step * step, player)
                        for step in range(1, 4)
                    ):
                        return True
        return False

    def matches(self, row, column, player):
        return (
            0 <= row < ROWS
            and 0 <= column < COLUMNS
            and self.cells[row][column] == player
        )
