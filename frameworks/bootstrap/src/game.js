const ROWS = 6;
const COLUMNS = 7;
const EMPTY = ".";
const PLAYERS = ["X", "O"];
const DIRECTIONS = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

const DISC_TONE = {
    X: "text-bg-danger",
    O: "text-bg-warning",
    ".": "text-bg-secondary",
};

const STATUS_TONE = {
    playing: "alert-info",
    win: "alert-success",
    tie: "alert-warning",
};

const statusEl = document.getElementById("status");
const statusText = statusEl.querySelector(".status-text");
const moveCount = document.getElementById("move-count");
const boardEl = document.getElementById("board");
const columnsEl = document.getElementById("columns");
const resetEl = document.getElementById("reset");

let board = createBoard();
let moves = 0;

function createBoard() {
    return Array.from({ length: ROWS }, () => Array(COLUMNS).fill(EMPTY));
}

function currentPlayer() {
    return PLAYERS[moves % PLAYERS.length];
}

function lowestEmptyRow(column) {
    for (let row = 0; row < ROWS; row += 1) {
        if (board[row][column] === EMPTY) {
            return row;
        }
    }
    return -1;
}

function isColumnFull(column) {
    return lowestEmptyRow(column) === -1;
}

function matches(row, column, player) {
    return (
        row >= 0 &&
        row < ROWS &&
        column >= 0 &&
        column < COLUMNS &&
        board[row][column] === player
    );
}

function winner() {
    for (const player of PLAYERS) {
        for (let row = 0; row < ROWS; row += 1) {
            for (let column = 0; column < COLUMNS; column += 1) {
                for (const [rowStep, columnStep] of DIRECTIONS) {
                    let line = true;
                    for (let step = 1; step <= 3; step += 1) {
                        if (!matches(row + rowStep * step, column + columnStep * step, player)) {
                            line = false;
                            break;
                        }
                    }
                    if (line) {
                        return player;
                    }
                }
            }
        }
    }
    return null;
}

function disc(label, filled) {
    const span = document.createElement("span");
    span.className = `d-inline-flex align-items-center justify-content-center rounded-circle ${
        DISC_TONE[label]
    }`;
    span.style.width = "2.5rem";
    span.style.height = "2.5rem";
    span.textContent = filled ? label : "";
    return span;
}

function render() {
    const champion = winner();
    const over = Boolean(champion) || moves === ROWS * COLUMNS;

    statusText.textContent = champion
        ? `Player ${champion} wins!`
        : over
        ? "It's a tie!"
        : `Player ${currentPlayer()}, choose a column.`;
    moveCount.textContent = `${moves} ${moves === 1 ? "move" : "moves"}`;
    statusEl.className = `alert d-flex justify-content-between align-items-center ${
        champion ? STATUS_TONE.win : over ? STATUS_TONE.tie : STATUS_TONE.playing
    }`;

    boardEl.replaceChildren();
    for (let row = ROWS - 1; row >= 0; row -= 1) {
        const tr = document.createElement("tr");
        for (let column = 0; column < COLUMNS; column += 1) {
            const cell = board[row][column];
            const td = document.createElement("td");
            td.className = "p-1";
            td.append(disc(cell, cell !== EMPTY));
            tr.append(td);
        }
        boardEl.append(tr);
    }

    columnsEl.replaceChildren();
    for (let column = 0; column < COLUMNS; column += 1) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "btn btn-outline-primary";
        button.textContent = String(column + 1);
        button.disabled = over || isColumnFull(column);
        button.addEventListener("click", () => play(column));
        columnsEl.append(button);
    }
}

function play(column) {
    if (winner() || moves === ROWS * COLUMNS || isColumnFull(column)) {
        return;
    }
    board[lowestEmptyRow(column)][column] = currentPlayer();
    moves += 1;
    render();
}

resetEl.addEventListener("click", () => {
    board = createBoard();
    moves = 0;
    render();
});

render();
