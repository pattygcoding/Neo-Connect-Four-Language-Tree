const http = require("node:http");

const {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} = require("./src/board");
const { createRenderer } = require("./src/render");

const render = createRenderer();
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
        status: champion
            ? `Player ${champion} wins!`
            : over
            ? "It's a tie!"
            : `Player ${currentPlayer(state.moves)}, choose a column.`,
        rows: [...state.cells].reverse(),
        columns: Array.from({ length: COLUMNS }, (_, column) => ({
            label: column + 1,
            disabled: over || isColumnFull(state.cells, column),
        })),
        over,
    };
}

function sendGame(response, id, state) {
    response.writeHead(200, {
        "Content-Type": "text/html; charset=utf-8",
        "Set-Cookie": `sid=${id}`,
    });
    response.end(render(view(state)));
}

function redirect(response, id) {
    response.writeHead(303, { Location: "/", "Set-Cookie": `sid=${id}` });
    response.end();
}

const server = http.createServer((request, response) => {
    const url = new URL(request.url, `http://${request.headers.host}`);
    const id = request.headers.cookie?.match(/sid=([^;]+)/)?.[1] ?? "default";
    const state = gameFor(id);

    if (url.pathname === "/move" && request.method === "POST") {
        let body = "";
        request.on("data", (chunk) => {
            body += chunk;
        });
        request.on("end", () => {
            const column = Number.parseInt(new URLSearchParams(body).get("column") ?? "", 10) - 1;
            const over = Boolean(winner(state.cells)) || state.moves === ROWS * COLUMNS;
            if (!over && column >= 0 && column < COLUMNS && !isColumnFull(state.cells, column)) {
                state.cells = drop(state.cells, column, currentPlayer(state.moves));
                state.moves += 1;
            }
            redirect(response, id);
        });
        return;
    }

    if (url.pathname === "/reset" && request.method === "POST") {
        games.set(id, { cells: createBoard(), moves: 0 });
        redirect(response, id);
        return;
    }

    sendGame(response, id, state);
});

server.listen(3000, () => {
    console.log("Connect Four (Handlebars) on http://localhost:3000");
});
