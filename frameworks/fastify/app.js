const path = require("node:path");

const cookie = require("@fastify/cookie");
const formbody = require("@fastify/formbody");
const session = require("@fastify/session");
const view = require("@fastify/view");
const ejs = require("ejs");
const fastify = require("fastify")({ logger: false });

const {
    ROWS,
    COLUMNS,
    createBoard,
    currentPlayer,
    isColumnFull,
    drop,
    winner,
} = require("./board");

fastify.register(view, { engine: { ejs }, root: path.join(__dirname, "views") });
fastify.register(formbody);
fastify.register(cookie);
fastify.register(session, {
    secret: "change-me-in-production-use-a-long-random-secret",
    cookie: { secure: false },
});

function currentGame(request) {
    return request.session.board ?? { cells: createBoard(), moves: 0 };
}

function status(game) {
    const champion = winner(game.cells);
    if (champion) {
        return `Player ${champion} wins!`;
    }
    if (game.moves === ROWS * COLUMNS) {
        return "It's a tie!";
    }
    return `Player ${currentPlayer(game.moves)}, choose a column.`;
}

fastify.get("/", (request, reply) => {
    const game = currentGame(request);
    return reply.view("board.ejs", {
        cells: [...game.cells].reverse(),
        columns: Array.from({ length: COLUMNS }, (_, index) => index + 1),
        status: status(game),
        over: winner(game.cells) !== undefined || game.moves === ROWS * COLUMNS,
    });
});

fastify.post("/move", (request, reply) => {
    const game = currentGame(request);
    const column = Number.parseInt(request.body.column, 10);

    if (column >= 1 && column <= COLUMNS && !isColumnFull(game.cells, column - 1)) {
        game.cells = drop(game.cells, column - 1, currentPlayer(game.moves));
        game.moves += 1;
    }

    request.session.board = game;
    return reply.redirect("/", 303);
});

fastify.post("/reset", (request, reply) => {
    delete request.session.board;
    return reply.redirect("/", 303);
});

const start = async () => {
    try {
        await fastify.listen({ port: 3000 });
    } catch (error) {
        fastify.log.error(error);
        process.exit(1);
    }
};

start();

module.exports = fastify;
