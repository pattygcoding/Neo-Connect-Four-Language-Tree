from board import COLUMNS, ROWS

DEPTH = 6
INFINITY = 1_000_000
WIN = 100_000

COLUMN_ORDER = (3, 2, 4, 1, 5, 0, 6)

RUN_SCORES = (0, 1, 8, 64, 100_000)


def _windows():
    """Every straight line of four cells on the board (69 of them)."""
    found = []
    for row in range(ROWS):
        for column in range(COLUMNS):
            for row_step, column_step in ((0, 1), (1, 0), (1, 1), (1, -1)):
                end_row = row + 3 * row_step
                end_column = column + 3 * column_step
                if 0 <= end_row < ROWS and 0 <= end_column < COLUMNS:
                    found.append(
                        tuple(
                            (row + index * row_step, column + index * column_step)
                            for index in range(4)
                        )
                    )
    return found


WINDOWS = _windows()


def evaluate(board, player):
    """Score a quiet position from `player`'s point of view.

    Each of the 69 windows of four is scored by how many of one player's discs
    it holds - and skipped entirely once both players have a disc in it, because
    that window can never become a line for either side.
    """
    opponent = board.other_player(player)
    score = 0
    for window in WINDOWS:
        values = [board.cells[row][column] for row, column in window]
        own = values.count(player)
        enemy = values.count(opponent)
        if own and enemy:
            continue
        score += RUN_SCORES[own] - RUN_SCORES[enemy]
    return score


def ordered_columns(board):
    """Open columns, centre first, so alpha-beta prunes as early as possible."""
    return [column for column in COLUMN_ORDER if not board.is_full(column)]


def minimax(board, depth, alpha, beta, ai_player):
    """Return the value of `board` for `ai_player` (classic minimax).

    Wins and losses score near +/-WIN, scaled by the depth at which they are
    found so the search prefers the quickest win and the slowest loss.
    """
    player = board.current_player
    maximizing = player == ai_player

    if board.moves == ROWS * COLUMNS:
        return 0
    if depth == 0:
        return evaluate(board, ai_player)

    best = -INFINITY if maximizing else INFINITY
    for column in ordered_columns(board):
        row = board.drop(column, player)
        if board.won_from(row, column, player):
            score = (WIN + depth) if maximizing else -(WIN + depth)
        else:
            score = minimax(board, depth - 1, alpha, beta, ai_player)
        board.undo(column, row)

        if maximizing:
            best = max(best, score)
            alpha = max(alpha, best)
        else:
            best = min(best, score)
            beta = min(beta, best)
        if alpha >= beta:
            break
    return best


def choose_move(board, ai_player, depth=DEPTH):
    """Best column for `ai_player`, which must be the side to move."""
    best_column = None
    best_score = -INFINITY
    for column in ordered_columns(board):
        row = board.drop(column, board.current_player)
        if board.won_from(row, column, ai_player):
            score = WIN + depth
        else:
            score = minimax(board, depth - 1, -INFINITY, INFINITY, ai_player)
        board.undo(column, row)

        if score > best_score:
            best_score = score
            best_column = column
    return best_column
