const path = require("node:path");

const express = require("express");
const session = require("express-session");

const {
    ROWS,
    COLUMNS,
    createBoard,
    currentPlayer,
    isColumnFull,
    drop,
    winner,
} = require("./board");

const app = express();

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));
app.use(express.urlencoded({ extended: false }));
app.use(
    session({
        secret: "change-me-in-production",
        resave: false,
        saveUninitialized: true,
    })
);

function currentGame(req) {
    return req.session.board ?? { cells: createBoard(), moves: 0 };
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

app.get("/", (req, res) => {
    const game = currentGame(req);
    res.render("board", {
        cells: [...game.cells].reverse(),
        columns: Array.from({ length: COLUMNS }, (_, index) => index + 1),
        status: status(game),
        over: winner(game.cells) !== undefined || game.moves === ROWS * COLUMNS,
    });
});

app.post("/move", (req, res) => {
    const game = currentGame(req);
    const column = Number.parseInt(req.body.column, 10);

    if (column >= 1 && column <= COLUMNS && !isColumnFull(game.cells, column - 1)) {
        game.cells = drop(game.cells, column - 1, currentPlayer(game.moves));
        game.moves += 1;
    }

    req.session.board = game;
    res.redirect(303, "/");
});

app.post("/reset", (req, res) => {
    delete req.session.board;
    res.redirect(303, "/");
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Connect Four on http://localhost:${port}`));

module.exports = app;
