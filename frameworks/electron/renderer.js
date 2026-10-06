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

function createBoard() {
    return Array.from({ length: ROWS }, () => Array(COLUMNS).fill(EMPTY));
}

function currentPlayer(moves) {
    return PLAYERS[moves % PLAYERS.length];
}

function lowestEmptyRow(board, column) {
    for (let row = 0; row < ROWS; row += 1) {
        if (board[row][column] === EMPTY) {
            return row;
        }
    }
    return -1;
}

function isColumnFull(board, column) {
    return lowestEmptyRow(board, column) === -1;
}

function drop(board, column, player) {
    const row = lowestEmptyRow(board, column);
    if (row === -1) {
        return board;
    }
    const next = board.map((cells) => [...cells]);
    next[row][column] = player;
    return next;
}

function matches(board, row, column, player) {
    return (
        row >= 0 &&
        row < ROWS &&
        column >= 0 &&
        column < COLUMNS &&
        board[row][column] === player
    );
}

function winner(board) {
    for (const player of PLAYERS) {
        for (let row = 0; row < ROWS; row += 1) {
            for (let column = 0; column < COLUMNS; column += 1) {
                for (const [rowStep, columnStep] of DIRECTIONS) {
                    let line = true;
                    for (let step = 1; step <= 3; step += 1) {
                        if (!matches(board, row + rowStep * step, column + columnStep * step, player)) {
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

function boot() {
    const boardEl = document.getElementById("board");
    const columnsEl = document.getElementById("columns");
    const statusEl = document.getElementById("status");
    const resetEl = document.getElementById("reset");

    let board = createBoard();
    let moves = 0;

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
                td.className = `cell cell--${cell.toLowerCase()}`;
                td.textContent = cell;
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

    resetEl.addEventListener("click", () => {
        board = createBoard();
        moves = 0;
        render();
    });

    render();
}

window.addEventListener("DOMContentLoaded", boot);
