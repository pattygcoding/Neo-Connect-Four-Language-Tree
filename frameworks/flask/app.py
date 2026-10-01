from flask import Flask, redirect, render_template, request, session, url_for

from board import COLUMNS, ConnectFourBoard

app = Flask(__name__)
app.secret_key = "change-me-in-production"


def current_board():
    return ConnectFourBoard.from_session(session.get("board"))


@app.get("/")
def board_page():
    board = current_board()
    return render_template("board.html", board=board, columns=range(1, COLUMNS + 1))


@app.post("/move")
def move():
    board = current_board()
    column = request.form.get("column", type=int)
    if column is not None and 1 <= column <= COLUMNS and not board.is_over:
        if not board.is_full(column - 1):
            board.drop(column - 1)
    session["board"] = board.to_session()
    return redirect(url_for("board_page"))


@app.post("/reset")
def reset():
    session.pop("board", None)
    return redirect(url_for("board_page"))
