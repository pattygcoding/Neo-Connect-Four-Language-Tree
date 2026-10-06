export const ROWS = 6;
export const COLUMNS = 7;
export const EMPTY = ".";
export const PLAYERS = ["X", "O"];

const DIRECTIONS = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

export function createBoard() {
    return Array.from({ length: ROWS }, () => Array(COLUMNS).fill(EMPTY));
}

export function currentPlayer(moves) {
    return PLAYERS[moves % PLAYERS.length];
}

export function lowestEmptyRow(board, column) {
    for (let row = 0; row < ROWS; row += 1) {
        if (board[row][column] === EMPTY) {
            return row;
        }
    }
    return -1;
}

export function isColumnFull(board, column) {
    return lowestEmptyRow(board, column) === -1;
}

export function drop(board, column, player) {
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

export function winner(board) {
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
