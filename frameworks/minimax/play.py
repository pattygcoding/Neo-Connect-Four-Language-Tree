import sys

from board import COLUMNS, Board
from minimax import DEPTH, choose_move


def render(board):
    header = " " + " ".join(str(column + 1) for column in range(COLUMNS))
    border = "+" + "-" * (COLUMNS * 2 - 1) + "+"
    lines = [header, border]
    for row in reversed(board.cells):
        lines.append("|" + " ".join(row) + "|")
    lines.append(border)
    return "\n".join(lines)


def main():
    depth = int(sys.argv[1]) if len(sys.argv) > 1 else DEPTH
    board = Board()

    print("Minimax AI - depth %d" % depth)
    print(render(board))

    while not board.is_over():
        player = board.current_player
        column = choose_move(board, player, depth)
        board.drop(column, player)
        print("Player %s drops in column %d" % (player, column + 1))
        print(render(board))

    winner = board.winner()
    print("Player %s wins!" % winner if winner else "It's a tie!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
