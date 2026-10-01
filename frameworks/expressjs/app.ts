import path from "node:path";

import express, { type Request, type Response } from "express";
import session from "express-session";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
    type Game,
} from "./board";

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

function currentGame(req: Request): Game {
    return req.session.board ?? { cells: createBoard(), moves: 0 };
}

function isOver(game: Game): boolean {
    return winner(game.cells) !== undefined || game.moves === ROWS * COLUMNS;
}

function status(game: Game): string {
    const champion = winner(game.cells);
    if (champion) {
        return `Player ${champion} wins!`;
    }
    if (game.moves === ROWS * COLUMNS) {
        return "It's a tie!";
    }
    return `Player ${currentPlayer(game.moves)}, choose a column.`;
}

app.get("/", (req: Request, res: Response) => {
    const game = currentGame(req);
    res.render("board", {
        cells: [...game.cells].reverse(),
        columns: Array.from({ length: COLUMNS }, (_, index) => index + 1),
        status: status(game),
        over: isOver(game),
    });
});

app.post("/move", (req: Request, res: Response) => {
    const game = currentGame(req);
    const column = Number.parseInt(req.body.column, 10);

    if (column >= 1 && column <= COLUMNS && !isOver(game) && !isColumnFull(game.cells, column - 1)) {
        game.cells = drop(game.cells, column - 1, currentPlayer(game.moves));
        game.moves += 1;
    }

    req.session.board = game;
    res.redirect(303, "/");
});

app.post("/reset", (req: Request, res: Response) => {
    delete req.session.board;
    res.redirect(303, "/");
});

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => console.log(`Connect Four on http://localhost:${port}`));

export default app;
