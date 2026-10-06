const http = require("node:http");

const {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} = require("./board");

const HTMX = "https://unpkg.com/htmx.org@2.0.4";
const sessions = new Map();

function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, (char) => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
    })[char]);
}

function boardFor(id) {
    if (!sessions.has(id)) {
        sessions.set(id, { cells: createBoard(), moves: 0 });
    }
    return sessions.get(id);
}

function statusLine(state) {
    const champion = winner(state.cells);
    const over = Boolean(champion) || state.moves === ROWS * COLUMNS;
    if (champion) {
        return `Player ${champion} wins!`;
    }
    if (over) {
        return "It's a tie!";
    }
    return `Player ${currentPlayer(state.moves)}, choose a column.`;
}

function renderGame(state) {
    const champion = winner(state.cells);
    const over = Boolean(champion) || state.moves === ROWS * COLUMNS;

    let rows = "";
    for (let row = ROWS - 1; row >= 0; row -= 1) {
        rows += "<tr>";
        for (let column = 0; column < COLUMNS; column += 1) {
            const cell = state.cells[row][column];
            rows += `<td class="cell cell--${cell.toLowerCase()}">${escapeHtml(cell)}</td>`;
        }
        rows += "</tr>";
    }

    let buttons = "";
    for (let column = 0; column < COLUMNS; column += 1) {
        const disabled = over || isColumnFull(state.cells, column) ? " disabled" : "";
        buttons +=
            `<button type="button"${disabled} ` +
            `hx-post="/move?column=${column + 1}" hx-target="#game" hx-swap="outerHTML">` +
            `${column + 1}</button>`;
    }

    return (
        `<section id="game">` +
        `<h1>Connect Four</h1>` +
        `<p role="status">${escapeHtml(statusLine(state))}</p>` +
        `<table class="board"><tbody>${rows}</tbody></table>` +
        `<div class="columns">${buttons}</div>` +
        `<button type="button" hx-post="/reset" hx-target="#game" hx-swap="outerHTML">New game</button>` +
        `</section>`
    );
}

function page(state) {
    return (
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">" +
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" +
        `<title>Connect Four - htmx</title>` +
        `<script src="${HTMX}"></script></head>` +
        `<body>${renderGame(state)}</body></html>`
    );
}

const server = http.createServer((request, response) => {
    const url = new URL(request.url, `http://${request.headers.host}`);
    const sessionId = request.headers.cookie?.match(/sid=([^;]+)/)?.[1] ?? "default";
    const state = boardFor(sessionId);

    if (url.pathname === "/move") {
        const column = Number.parseInt(url.searchParams.get("column") ?? "", 10) - 1;
        const over = Boolean(winner(state.cells)) || state.moves === ROWS * COLUMNS;
        if (!over && column >= 0 && column < COLUMNS && !isColumnFull(state.cells, column)) {
            drop(state.cells, column, currentPlayer(state.moves));
            state.moves += 1;
        }
        response.writeHead(200, {
            "Content-Type": "text/html; charset=utf-8",
            "Set-Cookie": `sid=${sessionId}`,
        });
        response.end(renderGame(state));
        return;
    }

    if (url.pathname === "/reset") {
        sessions.set(sessionId, { cells: createBoard(), moves: 0 });
        response.writeHead(200, {
            "Content-Type": "text/html; charset=utf-8",
            "Set-Cookie": `sid=${sessionId}`,
        });
        response.end(renderGame(sessions.get(sessionId)));
        return;
    }

    response.writeHead(200, {
        "Content-Type": "text/html; charset=utf-8",
        "Set-Cookie": `sid=${sessionId}`,
    });
    response.end(page(state));
});

server.listen(3000, () => {
    console.log("Connect Four (htmx) on http://localhost:3000");
});
