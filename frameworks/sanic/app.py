from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape
from sanic import Sanic
from sanic.response import html, redirect
from sanic_session import InMemorySessionInterface, Session

from board import COLUMNS, ConnectFourBoard

app = Sanic("connect_four")
Session(app, interface=InMemorySessionInterface())

templates = Environment(
    loader=FileSystemLoader(str(Path(__file__).parent / "templates")),
    autoescape=select_autoescape(["html"]),
)


@app.get("/")
async def board_page(request):
    board = ConnectFourBoard.from_session(request.ctx.session.get("board"))
    page = templates.get_template("board.html").render(
        board=board,
        columns=range(1, COLUMNS + 1),
    )
    return html(page)


@app.post("/move")
async def move(request):
    board = ConnectFourBoard.from_session(request.ctx.session.get("board"))
    raw = request.form.get("column")
    column = int(raw) if raw and raw.isdigit() else 0

    if not board.is_over and 1 <= column <= COLUMNS and not board.is_full(column - 1):
        board.drop(column - 1)

    request.ctx.session["board"] = board.to_session()
    return redirect("/")


@app.post("/reset")
async def reset(request):
    request.ctx.session.pop("board", None)
    return redirect("/")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
