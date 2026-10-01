from pathlib import Path

from fastapi import FastAPI, Form, Request
from fastapi.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware

from .board import COLUMNS, ConnectFourBoard

app = FastAPI(title="Connect Four")
app.add_middleware(SessionMiddleware, secret_key="change-me-in-production")

templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))


def current_board(request: Request) -> ConnectFourBoard:
    return ConnectFourBoard.from_session(request.session.get("board"))


@app.get("/")
def board_page(request: Request):
    board = current_board(request)
    return templates.TemplateResponse(
        request,
        "board.html",
        {"board": board, "columns": range(1, COLUMNS + 1)},
    )


@app.post("/move")
def move(request: Request, column: int = Form(ge=1, le=COLUMNS)):
    board = current_board(request)
    if not board.is_over and not board.is_full(column - 1):
        board.drop(column - 1)
    request.session["board"] = board.to_session()
    return RedirectResponse(url="/", status_code=303)


@app.post("/reset")
def reset(request: Request):
    request.session.pop("board", None)
    return RedirectResponse(url="/", status_code=303)
