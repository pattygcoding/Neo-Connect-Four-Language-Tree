from django.shortcuts import redirect, render

from .board import COLUMNS, ConnectFourBoard
from .forms import DropForm


def board(request):
    game = ConnectFourBoard.from_session(request.session.get("board"))
    context = {
        "board": game,
        "columns": range(1, COLUMNS + 1),
        "form": DropForm(),
    }
    return render(request, "game/board.html", context)


def move(request):
    game = ConnectFourBoard.from_session(request.session.get("board"))

    if request.method == "POST" and not game.is_over:
        form = DropForm(request.POST)
        if form.is_valid():
            column = form.cleaned_data["column"] - 1
            if not game.is_full(column):
                game.drop(column)

    request.session["board"] = game.to_session()
    return redirect("game:board")


def reset(request):
    request.session.pop("board", None)
    return redirect("game:board")
