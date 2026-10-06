from flask import Flask, jsonify, render_template, request

from board import COLUMNS, ConnectFourBoard
from coach import suggest_move

app = Flask(__name__)
games = {}


def game_for(name):
    if name not in games:
        games[name] = ConnectFourBoard()
    return games[name]


@app.get("/")
def board_page():
    board = game_for("default")
    return render_template("board.html", board=board, columns=range(1, COLUMNS + 1))


@app.post("/move")
def move():
    board = game_for("default")
    column = request.form.get("column", type=int)
    if column and not board.is_over and 1 <= column <= COLUMNS and not board.is_full(column - 1):
        board.drop(column - 1)
    return render_template("board.html", board=board, columns=range(1, COLUMNS + 1))


@app.get("/coach")
def coach():
    return jsonify({"advice": suggest_move(game_for("default"))})
