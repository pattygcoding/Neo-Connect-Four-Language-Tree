"use strict";

const readline = require("readline");

const ROWS = 6;
const COLS = 7;
const EMPTY = ".";
const PLAYERS = ["X", "O"];
const BORDER = "+" + "-".repeat(COLS * 2 - 1) + "+";
const LABELS = " " + Array.from({ length: COLS }, (_, i) => i + 1).join(" ");
const HEADER =
    "=== Connect Four ===\n" +
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

function newBoard() {
    return Array.from({ length: ROWS }, () => new Array(COLS).fill(EMPTY));
}

function render(board) {
    const lines = [LABELS, BORDER];
    for (let row = ROWS - 1; row >= 0; row--) {
        lines.push("|" + board[row].join(" ") + "|");
    }
    lines.push(BORDER);
    return lines.join("\n");
}

function lowestEmptyRow(board, column) {
    for (let row = 0; row < ROWS; row++) {
        if (board[row][column] === EMPTY) {
            return row;
        }
    }
    return -1;
}

function hasFour(board, player) {
    const at = (r, c) => board[r][c] === player;
    for (let r = 0; r < ROWS; r++) {
        for (let c = 0; c + 3 < COLS; c++) {
            if (at(r, c) && at(r, c + 1) && at(r, c + 2) && at(r, c + 3)) return true;
        }
    }
    for (let r = 0; r + 3 < ROWS; r++) {
        for (let c = 0; c < COLS; c++) {
            if (at(r, c) && at(r + 1, c) && at(r + 2, c) && at(r + 3, c)) return true;
        }
    }
    for (let r = 0; r + 3 < ROWS; r++) {
        for (let c = 0; c + 3 < COLS; c++) {
            if (at(r, c) && at(r + 1, c + 1) && at(r + 2, c + 2) && at(r + 3, c + 3)) {
                return true;
            }
        }
    }
    for (let r = 3; r < ROWS; r++) {
        for (let c = 0; c + 3 < COLS; c++) {
            if (at(r, c) && at(r - 1, c + 1) && at(r - 2, c + 2) && at(r - 3, c + 3)) {
                return true;
            }
        }
    }
    return false;
}

function isWholeNumber(token) {
    return /^[+-]?[0-9]+$/.test(token);
}

const rl = readline.createInterface({ input: process.stdin, terminal: false });
const pendingLines = [];
let pendingResolver = null;
let inputClosed = false;

rl.on("line", (line) => {
    if (pendingResolver) {
        const resolve = pendingResolver;
        pendingResolver = null;
        resolve(line);
    } else {
        pendingLines.push(line);
    }
});
rl.on("close", () => {
    inputClosed = true;
    if (pendingResolver) {
        const resolve = pendingResolver;
        pendingResolver = null;
        resolve(null);
    }
});

function readLine() {
    return new Promise((resolve) => {
        if (pendingLines.length) {
            resolve(pendingLines.shift());
        } else if (inputClosed) {
            resolve(null);
        } else {
            pendingResolver = resolve;
        }
    });
}

async function askColumn(board, player) {
    for (;;) {
        process.stdout.write("Player " + player + ", choose a column (1-7): ");
        const raw = await readLine();
        if (raw === null) {
            process.stdout.write("\nInput closed. Goodbye.\n");
            return null;
        }
        const token = raw.trim();
        let message;
        if (token === "") {
            message = "Invalid input: no column entered.";
        } else if (!isWholeNumber(token)) {
            message = 'Invalid input: "' + token + '" is not a whole number.';
        } else {
            const value = Number(token);
            if (!(value >= 1 && value <= COLS)) {
                message = 'Invalid input: "' + token + '" is out of range (1-7).';
            } else if (lowestEmptyRow(board, value - 1) === -1) {
                message = "Column " + value + " is full.";
            } else {
                return value - 1;
            }
        }
        process.stdout.write("\n" + message + "\n");
    }
}

async function main() {
    const board = newBoard();
    process.stdout.write(HEADER + "\n" + render(board) + "\n");
    let moves = 0;
    let playerIndex = 0;
    for (;;) {
        const player = PLAYERS[playerIndex];
        const column = await askColumn(board, player);
        if (column === null) {
            return;
        }
        board[lowestEmptyRow(board, column)][column] = player;
        moves++;
        process.stdout.write("\n" + render(board) + "\n");
        if (hasFour(board, player)) {
            process.stdout.write("Player " + player + " wins!\n");
            return;
        }
        if (moves === ROWS * COLS) {
            process.stdout.write("It's a tie!\n");
            return;
        }
        playerIndex = 1 - playerIndex;
    }
}

main().then(() => {
    rl.close();
    process.stdout.write("", () => process.exit(0));
});
