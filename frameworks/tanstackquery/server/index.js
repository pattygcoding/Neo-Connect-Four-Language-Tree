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

const games = new Map();

function gameFor(id) {
    if (!games.has(id)) {
        games.set(id, { cells: createBoard(), moves: 0 });
    }
    return games.get(id);
}

function view(state) {
    const champion = winner(state.cells);
    const over = Boolean(champion) || state.moves === ROWS * COLUMNS;
    return {
        rows: [...state.cells].reverse(),
        status: champion
            ? `Player ${champion} wins!`
            : over
            ? "It's a tie!"
            : `Player ${currentPlayer(state.moves)}, choose a column.`,
        over,
        full: Array.from({ length: COLUMNS }, (_, column) => isColumnFull(state.cells, column)),
    };
}

function send(response, payload) {
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify(payload));
}

const server = http.createServer((request, response) => {
    const url = new URL(request.url, `http://${request.headers.host}`);
    const id = request.headers.cookie?.match(/sid=([^;]+)/)?.[1] ?? "default";
    const state = gameFor(id);

    if (url.pathname === "/api/move") {
        const column = Number.parseInt(url.searchParams.get("column") ?? "", 10);
        const over = Boolean(winner(state.cells)) || state.moves === ROWS * COLUMNS;
        if (!over && column >= 0 && column < COLUMNS && !isColumnFull(state.cells, column)) {
            state.cells = drop(state.cells, column, currentPlayer(state.moves));
            state.moves += 1;
        }
        return send(response, view(state));
    }

    if (url.pathname === "/api/reset") {
        games.set(id, { cells: createBoard(), moves: 0 });
        return send(response, view(games.get(id)));
    }

    send(response, view(state));
});

server.listen(3001, () => {
    console.log("Connect Four API on http://localhost:3001");
});
