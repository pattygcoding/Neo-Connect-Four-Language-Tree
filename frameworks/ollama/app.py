import re

import ollama

from board import COLUMNS, ConnectFourBoard

MODEL = "llama3.2"

PROMPT = (
    "You are playing Connect Four as the O player. Reply with exactly one "
    "column number between 1 and 7 and nothing else.\n\n"
    "Board (top row first, bottom row last):\n{board}\n\n"
    "Legal columns: {legal}\nYour move:"
)


def choose_ai_move(board):
    legal = [column + 1 for column in board.legal_columns()]
    reply = ollama.chat(
        model=MODEL,
        messages=[{"role": "user", "content": PROMPT.format(board=board.render(), legal=legal)}],
        options={"temperature": 0.2},
    )
    text = reply["message"]["content"]
    for match in re.finditer(r"[1-7]", text):
        column = int(match.group()) - 1
        if column in board.legal_columns():
            return column
    return board.legal_columns()[0]


def choose_human_move(board):
    legal = [column + 1 for column in board.legal_columns()]
    while True:
        raw = input("Choose a column %s: " % legal).strip()
        if raw.isdigit() and int(raw) in legal:
            return int(raw) - 1
        print("That column is not available.")


def main():
    board = ConnectFourBoard()

    while not board.is_over:
        print(board.render())
        print()

        if board.current_player == "O":
            column = choose_ai_move(board)
            print("Ollama plays column %d." % (column + 1))
        else:
            column = choose_human_move(board)

        board.drop(column)
        print()

    print(board.render())
    print("Player %s wins!" % board.winner if board.winner else "It's a tie!")


if __name__ == "__main__":
    main()
