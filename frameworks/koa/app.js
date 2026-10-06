import Koa from "koa";
import Router from "@koa/router";
import bodyParser from "koa-bodyparser";
import session from "koa-session";

import {
    COLUMNS,
    ROWS,
    countMoves,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./lib/board.js";

const app = new Koa();
app.keys = ["change-me-in-production"];
app.use(session(app));
app.use(bodyParser());

function boardFrom(sessionState) {
    return sessionState.board ?? createBoard();
}

function renderBoard(board) {
    const champion = winner(board);
    const moves = countMoves(board);
    const over = Boolean(champion) || moves === ROWS * COLUMNS;

    let rows = "";
    for (let row = ROWS - 1; row >= 0; row -= 1) {
        rows += "<tr>";
        for (let column = 0; column < COLUMNS; column += 1) {
            const cell = board[row][column];
            rows += `<td class="cell cell--${cell.toLowerCase()}">${cell}</td>`;
        }
        rows += "</tr>";
    }

    let buttons = "";
    for (let column = 0; column < COLUMNS; column += 1) {
        const disabled = over || isColumnFull(board, column) ? " disabled" : "";
        buttons += `<button type="submit" name="column" value="${column + 1}"${disabled}>${column + 1}</button>`;
    }

    const status = champion
        ? `Player ${champion} wins!`
        : over
        ? "It's a tie!"
        : `Player ${currentPlayer(moves)}, choose a column.`;

    return (
        `<!doctype html><html lang="en"><head><meta charset="utf-8">` +
        `<title>Connect Four</title></head><body>` +
        `<h1>Connect Four</h1><p>${status}</p>` +
        `<table class="board">${rows}</table>` +
        `<form method="post" action="/move">${buttons}</form>` +
        `<form method="post" action="/reset"><button type="submit">New game</button></form>` +
        `</body></html>`
    );
}

const router = new Router();

router.get("/", (ctx) => {
    ctx.type = "text/html";
    ctx.body = renderBoard(boardFrom(ctx.session));
});

router.post("/move", (ctx) => {
    const board = boardFrom(ctx.session);
    const column = Number.parseInt(ctx.request.body.column, 10) - 1;
    const moves = countMoves(board);
    if (
        !winner(board) &&
        moves < ROWS * COLUMNS &&
        column >= 0 &&
        column < COLUMNS &&
        !isColumnFull(board, column)
    ) {
        ctx.session.board = drop(board, column);
    }
    ctx.redirect("/");
});

router.post("/reset", (ctx) => {
    ctx.session = null;
    ctx.redirect("/");
});

app.use(router.routes());
app.use(router.allowedMethods());

app.listen(3000, () => {
    console.log("Connect Four (Koa) on http://localhost:3000");
});
