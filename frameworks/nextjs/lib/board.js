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
    return board.map((cells, index) =>
        index === row ? cells.map((cell, position) => (position === column ? player : cell)) : cells
    );
}

export function matches(board, row, column, player) {
    return (
        row >= 0 &&
        row < ROWS &&
        column >= 0 &&
        column < COLUMNS &&
        board[row][column] === player
    );
}

export function winner(board) {
    return PLAYERS.find((player) =>
        board.some((cells, row) =>
            cells.some(
                (cell, column) =>
                    cell === player &&
                    DIRECTIONS.some(
                        ([rowStep, columnStep]) =>
                            matches(board, row + rowStep, column + columnStep, player) &&
                            matches(board, row + rowStep * 2, column + columnStep * 2, player) &&
                            matches(board, row + rowStep * 3, column + columnStep * 3, player)
                    )
            )
        )
    );
}
