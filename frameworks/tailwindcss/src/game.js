import { COLUMNS, ROWS, createBoard, currentPlayer, drop, isColumnFull, winner } from "./board.js";

const boardEl = document.getElementById("board");
const columnsEl = document.getElementById("columns");
const statusEl = document.getElementById("status");
const resetEl = document.getElementById("reset");

let board = createBoard();
let moves = 0;

const DISC = {
    X: "bg-red-500",
    O: "bg-yellow-400",
    ".": "bg-slate-900",
};

function render() {
    const champion = winner(board);
    const over = Boolean(champion) || moves === ROWS * COLUMNS;

    statusEl.textContent = champion
        ? `Player ${champion} wins!`
        : over
        ? "It's a tie!"
        : `Player ${currentPlayer(moves)}, choose a column.`;

    boardEl.replaceChildren();
    for (let row = ROWS - 1; row >= 0; row -= 1) {
        const tr = document.createElement("tr");
        for (let column = 0; column < COLUMNS; column += 1) {
            const cell = board[row][column];
            const td = document.createElement("td");
            td.className = "p-1";
            const disc = document.createElement("div");
            disc.className = `h-10 w-10 rounded-full ${DISC[cell]}`;
            td.append(disc);
            tr.append(td);
        }
        boardEl.append(tr);
    }

    columnsEl.replaceChildren();
    for (let column = 0; column < COLUMNS; column += 1) {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = String(column + 1);
        button.disabled = over || isColumnFull(board, column);
        button.className =
            "rounded-md bg-slate-700 py-1 font-mono text-sm transition hover:bg-slate-600 disabled:opacity-30";
        button.addEventListener("click", () => play(column));
        columnsEl.append(button);
    }
}

function play(column) {
    if (winner(board) || moves === ROWS * COLUMNS || isColumnFull(board, column)) {
        return;
    }
    board = drop(board, column, currentPlayer(moves));
    moves += 1;
    render();
}

function reset() {
    board = createBoard();
    moves = 0;
    render();
}

resetEl.addEventListener("click", reset);
render();
