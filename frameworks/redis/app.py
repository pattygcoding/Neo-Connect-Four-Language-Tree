import os
import secrets

import redis
from flask import Flask, redirect, render_template, request, session

from board import COLUMNS, ConnectFourBoard

app = Flask(__name__)
app.secret_key = "change-me-in-production"

store = redis.Redis.from_url(os.environ.get("REDIS_URL", "redis://localhost:6379/0"))


def game_key():
    if "game" not in session:
        session["game"] = secrets.token_hex(8)
    return f"connectfour:{session['game']}"


def load_board():
    return ConnectFourBoard.from_json(store.get(game_key()))


@app.get("/")
def board_page():
    board = load_board()
    return render_template("board.html", board=board, columns=range(1, COLUMNS + 1))


@app.post("/move")
def move():
    board = load_board()
    column = request.form.get("column", type=int)

    if column and not board.is_over and 1 <= column <= COLUMNS and not board.is_full(column - 1):
        board.drop(column - 1)

    store.set(game_key(), board.to_json())
    return redirect("/")


@app.post("/reset")
def reset():
    store.delete(game_key())
    return redirect("/")


@app.get("/history")
def history():
    board = load_board()
    return {"moves": board.moves}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
