import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

DIRECTIONS = ((0, 1), (1, 0), (1, 1), (1, -1))


def load_game(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def new_board(rows, columns, empty):
    return [[empty for _ in range(columns)] for _ in range(rows)]


def render(board, columns):
    header = " " + " ".join(str(column + 1) for column in range(columns))
    border = "+" + "-" * (columns * 2 - 1) + "+"
    lines = [header, border]
    for row in reversed(board):
        lines.append("|" + " ".join(row) + "|")
    lines.append(border)
    return "\n".join(lines)


def lowest_empty_row(board, column, empty):
    for row in range(len(board)):
        if board[row][column] == empty:
            return row
    return -1


def has_line(board, player):
    rows = len(board)
    columns = len(board[0])
    for row in range(rows):
        for column in range(columns):
            if board[row][column] != player:
                continue
            for row_step, column_step in DIRECTIONS:
                if all(
                    0 <= row + index * row_step < rows
                    and 0 <= column + index * column_step < columns
                    and board[row + index * row_step][column + index * column_step] == player
                    for index in range(4)
                ):
                    return True
    return False


def play(game):
    rows = game["rows"]
    columns = game["columns"]
    empty = game["empty"]
    players = game["players"]
    board = new_board(rows, columns, empty)

    print(game.get("title", "Connect Four"))
    print(render(board, columns))

    winner = None
    placed = 0
    for column in game["moves"]:
        # Skipped moves (off the board or a full column) do not pass the turn.
        player = players[placed % len(players)]
        if not 1 <= column <= columns:
            continue
        row = lowest_empty_row(board, column - 1, empty)
        if row < 0:
            continue
        board[row][column - 1] = player
        placed += 1
        print(render(board, columns))
        if has_line(board, player):
            winner = player
            break
        if placed == rows * columns:
            break

    if winner:
        print("Player %s wins!" % winner)
    elif placed == rows * columns:
        print("It's a tie!")
    else:
        print("Game not finished.")


if __name__ == "__main__":
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "connect_four.json"
    play(load_game(path))
